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

            VStack(spacing: 0) {
                Spacer()

                // ── HEADER BLOCK ──
                VStack(spacing: 16) {
                    // Minimalist App Icon Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(white: 0.08))
                            .frame(width: 88, height: 88)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )

                        if let icon = UIImage(named: "ModToolsLogo")
                            ?? UIImage(named: "AppIcon60x60")
                            ?? UIImage(named: "AppIcon") {
                            Image(uiImage: icon)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    // Brand Title & Tag
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Text("MOD TOOLS")
                                .font(.system(size: 22, weight: .black, design: .default))
                                .foregroundStyle(.white)
                                .kerning(2.5)

                            Text("PRO")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }

                        Text("Enter your license key to access tools")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color(white: 0.50))
                    }
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
                                .fill(Color(white: 0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.white.opacity(keyInput.isEmpty ? 0.12 : 0.28), lineWidth: 1)
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
                                .foregroundStyle(Color(white: 0.45))
                        }
                        .padding(.trailing, 16)
                    }

                    // Error message
                    if let error = license.lastError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white)
                            Text(error)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Activate button (High-contrast clean white flat button)
                    Button(action: submitKey) {
                        ZStack {
                            if license.isChecking {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.black)
                                        .scaleEffect(0.85)
                                    Text("VERIFYING...")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(Color.black.opacity(0.8))
                                        .kerning(1.5)
                                }
                            } else {
                                Text("ACTIVATE")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundStyle(keyInput.isEmpty ? Color(white: 0.40) : Color.black)
                                    .kerning(2.0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            keyInput.isEmpty || license.isChecking
                                ? Color(white: 0.12)
                                : Color.white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(keyInput.isEmpty ? 0.10 : 0.0), lineWidth: 1)
                        )
                    }
                    .disabled(keyInput.isEmpty || license.isChecking)
                }
                .padding(.horizontal, 28)
                .animation(.easeInOut(duration: 0.2), value: license.lastError)

                Spacer()

                // ── FOOTER BUTTONS ──
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        // Buy Key (Minimalist)
                        Button {
                            if let url = URL(string: "https://wa.me/6283899369257") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("BUY KEY")
                                    .font(.system(size: 11, weight: .bold))
                                    .kerning(1.0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .foregroundStyle(.white)
                            .background(Color(white: 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }

                        // Channel (Minimalist)
                        Button {
                            if let url = URL(string: "https://whatsapp.com/channel/0029Vb800WiJkK74Ssu8Fx0i") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("CHANNEL")
                                    .font(.system(size: 11, weight: .bold))
                                    .kerning(1.0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .foregroundStyle(.white)
                            .background(Color(white: 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 28)

                    Text("Device locked after first key activation")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color(white: 0.32))
                        .padding(.bottom, 24)
                        .padding(.top, 2)
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
