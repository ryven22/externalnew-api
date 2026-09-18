import SwiftUI

// MARK: - LicenseGateView

struct LicenseGateView<Content: View>: View {
    @StateObject private var license = LicenseService.shared
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if let state = license.licenseState, state.isValid {
            content()
        } else {
            KeyEntryView()
        }
    }
}

// MARK: - KeyEntryView (Black & White Basic Style)

struct KeyEntryView: View {
    @StateObject private var license = LicenseService.shared
    @State private var keyInput = ""
    @State private var shaking = false
    @State private var keyVisible = false

    var body: some View {
        ZStack {
            // Pure pitch black background
            Color.black.ignoresSafeArea()

            // Subtle monochrome top glow
            VStack {
                RadialGradient(
                    colors: [Color(white: 0.12), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 260
                )
                .frame(height: 260)
                .offset(y: -60)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── HEADER BLOCK ──
                VStack(spacing: 0) {

                    // Top accent bar
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 42, height: 2)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)

                    // App Icon / Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(white: 0.08))
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            )

                        if let icon = UIImage(named: "ModToolsLogo")
                            ?? UIImage(named: "AppIcon60x60")
                            ?? UIImage(named: "AppIcon") {
                            Image(uiImage: icon)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        } else {
                            Text("MT")
                                .font(.system(size: 38, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.bottom, 20)

                    // Brand Title
                    HStack(spacing: 8) {
                        Text("MOD TOOLS")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                            .kerning(2.0)
                        Text("PRO")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }

                    // Divider
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color(white: 0.18))
                            .frame(height: 1)
                        Text("SECURITY ENGINE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(white: 0.45))
                            .kerning(2.5)
                            .fixedSize()
                        Rectangle()
                            .fill(Color(white: 0.18))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                    Text("Enter your license key to continue")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(white: 0.45))
                        .padding(.top, 6)
                }

                Spacer().frame(height: 36)

                // ── INPUT BLOCK ──
                VStack(spacing: 14) {

                    // Key field
                    ZStack(alignment: .trailing) {
                        Group {
                            if keyVisible {
                                TextField("XXXX-XXXX-XXXX-XXXX", text: $keyInput)
                                    .textContentType(.none)
                            } else {
                                SecureField("XXXX-XXXX-XXXX-XXXX", text: $keyInput)
                                    .textContentType(.none)
                            }
                        }
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(white: 0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color(white: 0.24), lineWidth: 1)
                                )
                        )
                        .offset(x: shaking ? -8 : 0)
                        .animation(
                            shaking
                                ? .default.repeatCount(4, autoreverses: true).speed(8)
                                : .default,
                            value: shaking
                        )

                        // Eye toggle
                        Button {
                            keyVisible.toggle()
                        } label: {
                            Image(systemName: keyVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(white: 0.5))
                        }
                        .padding(.trailing, 14)
                    }

                    // Error message
                    if let error = license.lastError {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 3, height: 14)
                                .clipShape(Capsule())
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Activate button (High-contrast full white / basic style)
                    Button(action: submitKey) {
                        ZStack {
                            if license.isChecking {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.black)
                                        .scaleEffect(0.85)
                                    Text("Checking...")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Color.black.opacity(0.8))
                                }
                            } else {
                                Text("ACTIVATE")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(keyInput.isEmpty ? Color(white: 0.40) : Color.black)
                                    .kerning(2.0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            keyInput.isEmpty || license.isChecking
                                ? Color(white: 0.16)
                                : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(white: 0.25), lineWidth: keyInput.isEmpty ? 1 : 0)
                        )
                    }
                    .disabled(keyInput.isEmpty || license.isChecking)
                }
                .padding(.horizontal, 28)
                .animation(.easeInOut(duration: 0.2), value: license.lastError)

                Spacer()

                // ── FOOTER BUTTONS ──
                VStack(spacing: 12) {
                    // Thin separator
                    HStack(spacing: 8) {
                        Rectangle().fill(Color(white: 0.14)).frame(height: 1)
                        Text("CONTACT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color(white: 0.35))
                            .kerning(2)
                            .fixedSize()
                        Rectangle().fill(Color(white: 0.14)).frame(height: 1)
                    }
                    .padding(.horizontal, 28)

                    HStack(spacing: 10) {
                        // Buy Key (Monochrome)
                        Button {
                            if let url = URL(string: "https://wa.me/6283899369257") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("BUY KEY")
                                    .font(.system(size: 12, weight: .bold))
                                    .kerning(1.0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(Color(white: 0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(white: 0.26), lineWidth: 1)
                            )
                        }

                        // Channel (Monochrome)
                        Button {
                            if let url = URL(string: "https://whatsapp.com/channel/0029Vb800WiJkK74Ssu8Fx0i") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("CHANNEL")
                                    .font(.system(size: 12, weight: .bold))
                                    .kerning(1.0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.white)
                            .background(Color(white: 0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(white: 0.26), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 28)

                    Text("Key is bound to this device on first activation")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(white: 0.28))
                        .padding(.bottom, 28)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func submitKey() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            let success = await license.validate(key: trimmed)
            if !success {
                await MainActor.run {
                    shaking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shaking = false }
                }
            }
        }
    }
}
