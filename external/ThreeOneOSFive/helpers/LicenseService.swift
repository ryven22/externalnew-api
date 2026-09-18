import Foundation
import UIKit

// MARK: - Models

struct LicenseValidateResponse: Codable {
    let valid: Bool?
    let expiresAt: String?
    let durationDays: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case valid
        case expiresAt = "expires_at"
        case durationDays = "duration_days"
        case error
    }
}

struct LicenseState: Codable {
    let key: String
    let expiresAt: Date
    let activatedAt: Date

    var isValid: Bool {
        Date() < expiresAt
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0)
    }
}

// MARK: - LicenseService

final class LicenseService: ObservableObject {

    // ⚠️ Server API URL
    static let apiBaseURL = "https://apinewup.vercel.app"


    // Master keys that can activate offline permanently (Owner / Developer emergency bypass)
    private static let masterKeys: Set<String> = [
        "2EAY-C1N4-TUQN-MKJG",
        "MODTOOLS-MASTER",
        "MODTOOLS-VIP",
        "MODTOOLS",
        "REGSXD-MASTER",
        "REGSXD18",
        "REGSXD-VIP",
        "REGSXD"
    ]

    static let shared = LicenseService()

    @Published var licenseState: LicenseState?
    @Published var isChecking = false
    @Published var lastError: String?

    private let stateKey = "regsxd_license_state"
    private let deviceID: String = {
        if let saved = UserDefaults.standard.string(forKey: "regsxd_device_id") {
            return saved
        }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: "regsxd_device_id")
        return id
    }()

    private init() {
        loadSavedState()
    }

    // MARK: - Public

    /// Validate key against server or master keys.
    func validate(key: String) async -> Bool {
        await MainActor.run { isChecking = true; lastError = nil }

        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 1. Offline Master / Owner Key Validation (Instant bypass without network)
        if Self.masterKeys.contains(cleanKey) {
            // Valid until year 2100 (lifetime)
            let distantExpiry = Date(timeIntervalSince1970: 4102444800)
            let state = LicenseState(key: cleanKey, expiresAt: distantExpiry, activatedAt: Date())
            saveState(state)
            await MainActor.run {
                self.licenseState = state
                self.isChecking = false
                self.lastError = nil
            }
            return true
        }

        guard let url = URL(string: "\(Self.apiBaseURL)/api/validate") else {
            await MainActor.run { isChecking = false; lastError = "Invalid server URL" }
            return false
        }

        // 2. Configure robust URLSession for cellular & wifi
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = true
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 30
        let session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 25

        let body: [String: String] = ["key": cleanKey, "device_id": deviceID]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (data, rawResponse) = try await session.data(for: request)
            let httpResponse = rawResponse as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 200

            let response = try? JSONDecoder().decode(LicenseValidateResponse.self, from: data)

            if statusCode == 200, let resp = response, resp.valid == true, let expiresAtStr = resp.expiresAt {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let expiresAt = formatter.date(from: expiresAtStr)
                    ?? ISO8601DateFormatter().date(from: expiresAtStr)
                    ?? Date().addingTimeInterval(86400)

                let state = LicenseState(key: cleanKey, expiresAt: expiresAt, activatedAt: Date())
                saveState(state)
                await MainActor.run { self.licenseState = state; isChecking = false }
                return true
            } else {
                let errorMsg: String
                if let serverErr = response?.error {
                    errorMsg = serverErr
                } else if statusCode != 200 {
                    errorMsg = "Server error (HTTP \(statusCode))"
                } else {
                    errorMsg = "Invalid key"
                }

                await MainActor.run {
                    self.isChecking = false
                    self.lastError = errorMsg
                    self.licenseState = nil
                }
                clearState()
                return false
            }
        } catch let urlError as URLError {
            // Offline fallback — use cached state if still valid
            if let cached = licenseState, cached.isValid {
                await MainActor.run { isChecking = false }
                return true
            }

            let msg: String
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                msg = "Tidak ada koneksi. Cek izin data seluler di Pengaturan."
            case .timedOut:
                msg = "Koneksi timeout. Sinyal lemah atau server lambat."
            case .cannotFindHost, .dnsLookupFailed:
                msg = "DNS gagal / diblokir. Coba gunakan 1.1.1.1 WARP."
            case .secureConnectionFailed, .serverCertificateUntrusted:
                msg = "SSL diblokir provider. Coba gunakan 1.1.1.1 WARP."
            default:
                msg = "\(urlError.localizedDescription) (\(urlError.errorCode))"
            }

            await MainActor.run {
                self.isChecking = false
                self.lastError = msg
            }
            return false
        } catch {
            if let cached = licenseState, cached.isValid {
                await MainActor.run { isChecking = false }
                return true
            }
            await MainActor.run {
                self.isChecking = false
                self.lastError = "Error: \(error.localizedDescription)"
            }
            return false
        }
    }

    func logout() {
        clearState()
        DispatchQueue.main.async { self.licenseState = nil }
    }

    // MARK: - Private

    private func saveState(_ state: LicenseState) {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private func loadSavedState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(LicenseState.self, from: data),
              state.isValid else {
            clearState()
            return
        }
        licenseState = state
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }
}
