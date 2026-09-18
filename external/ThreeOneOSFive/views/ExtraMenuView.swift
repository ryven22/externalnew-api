import SwiftUI

// MARK: - Extra Menu View

struct ExtraMenuView: View {
    @State private var selectedTarget: TargetGame = .freefireTH
    @State private var results: [UUID: InjectResult] = [:]
    @State private var working: UUID? = nil
    @State private var progress: [UUID: Double] = [:]
    @State private var consoleLogs: [String] = []
    @State private var openGameWorking: UUID? = nil

    let openGameButtons: [OpenGameButton] = [
        OpenGameButton(
            name: "Free Fire",
            bundleID: "com.dts.freefireth",
            urlSchemes: ["freefire://", "garena://"],
            appStoreID: "id1300146617"
        ),
        OpenGameButton(
            name: "Free Fire MAX",
            bundleID: "com.dts.freefiremax",
            urlSchemes: ["freefiremax://", "garena://"],
            appStoreID: "id1489675801"
        ),
    ]

    private func extraButtons(for target: TargetGame) -> [InjectButton] {
        switch target {
        case .freefireTH:
            return [
                InjectButton(
                    name: "FPS 140",
                    category: "EXTRA",
                    bundleID: target.rawValue,
                    targetPath: "Library/Preferences/com.dts.freefireth.plist",
                    resourceFileName: "com.dts.freefireth.plist",
                    resourceSubfolder: "patches/fps 140",
                    launchAfterInject: false
                ),
            ]
        case .freefireMax:
            return [
                InjectButton(
                    name: "FPS 140",
                    category: "EXTRA",
                    bundleID: target.rawValue,
                    targetPath: "Library/Preferences/com.dts.freefiremax.plist",
                    resourceFileName: "com.dts.freefiremax.plist",
                    resourceSubfolder: "patches/fps 140",
                    launchAfterInject: false
                ),
            ]
        }
    }

    private func log(_ msg: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        DispatchQueue.main.async {
            consoleLogs.append("[\(ts)] \(msg)")
            if consoleLogs.count > 40 { consoleLogs.removeFirst() }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {

                            // MARK: Target Selector
                            targetSelector

                            // MARK: EXTRA patch buttons
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("EXTRA FEATURES")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .kerning(1.5)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(height: 1)
                                }
                                .padding(.horizontal, 16)

                                VStack(spacing: 10) {
                                    ForEach(extraButtons(for: selectedTarget)) { button in
                                        InjectButtonCard(
                                            button: button,
                                            result: results[button.id],
                                            isWorking: working == button.id,
                                            progress: progress[button.id] ?? 0
                                        ) {
                                            inject(button)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            // MARK: OPEN GAME buttons
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("LAUNCH GAME")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                        .kerning(1.5)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(height: 1)
                                }
                                .padding(.horizontal, 16)

                                HStack(spacing: 10) {
                                    ForEach(openGameButtons) { btn in
                                        OpenGameButtonCard(
                                            button: btn,
                                            isWorking: openGameWorking == btn.id
                                        ) {
                                            openGame(btn)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    }

                    ConsoleView(logs: consoleLogs)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Extra")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedTarget) { _ in
                results = [:]
                working = nil
                progress = [:]
            }
        }
    }

    // MARK: - Target Selector View

    private var targetSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Text("TARGET APPLICATION")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(white: 0.45))
                    .kerning(1.5)
                Spacer()
            }
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ForEach(TargetGame.allCases) { target in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTarget = target
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(selectedTarget == target ? Color.white : Color(white: 0.25))
                                .frame(width: 6, height: 6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(target.shortTag)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(selectedTarget == target ? Color.white : Color(white: 0.40))
                                    .kerning(1)
                                Text(target.displayName)
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(selectedTarget == target ? .white : Color(white: 0.45))
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedTarget == target ? Color(white: 0.12) : Color(white: 0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selectedTarget == target ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(white: 0.40))
                Text(selectedTarget.rawValue)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(white: 0.35))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Inject Logic

    private func inject(_ button: InjectButton) {
        guard working != button.id else { return }

        let resourceURL: URL? = {
            let bundleBase = URL(fileURLWithPath: Bundle.main.bundlePath)
            let subfolderPath = bundleBase
                .appendingPathComponent(button.resourceSubfolder)
                .appendingPathComponent(button.resourceFileName)
            if FileManager.default.fileExists(atPath: subfolderPath.path) {
                return subfolderPath
            }
            let rootPath = bundleBase.appendingPathComponent(button.resourceFileName)
            return FileManager.default.fileExists(atPath: rootPath.path) ? rootPath : nil
        }()

        guard let resourceURL else {
            results[button.id] = .failed("File not found in bundle")
            log("\(button.name) [\(selectedTarget.shortTag)] — inject error: file not found")
            return
        }

        working = button.id
        results[button.id] = .working
        progress[button.id] = 0

        let id = button.id
        let tag = selectedTarget.shortTag
        let startTime = Date()
        let duration: Double = 5.0

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let pct = min(elapsed / duration, 1.0)
            DispatchQueue.main.async { progress[id] = pct }
            if pct >= 1.0 { timer.invalidate() }
        }

        Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            do {
                let containerURL = try resolveContainer(bundleID: button.bundleID)
                let targetURL = containerURL.appendingPathComponent(button.targetPath)
                let dir = targetURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let data = try Data(contentsOf: resourceURL)
                let staging = dir.appendingPathComponent(".regsxd-inject-\(UUID().uuidString)")
                try data.write(to: staging, options: .atomic)
                let renameResult = rename(staging.path, targetURL.path)
                if renameResult != 0 {
                    let errMsg = String(cString: strerror(errno))
                    try? FileManager.default.removeItem(at: staging)
                    throw InjectError.renameFailed(errMsg)
                }
                await MainActor.run {
                    results[button.id] = .success
                    progress[button.id] = 1.0
                    working = nil
                    log("\(button.name) [\(tag)] — apply success")
                }
            } catch {
                await MainActor.run {
                    results[button.id] = .failed(error.localizedDescription)
                    working = nil
                    log("\(button.name) [\(tag)] — inject error: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Open Game Logic

    private func openGame(_ button: OpenGameButton) {
        guard openGameWorking != button.id else { return }
        openGameWorking = button.id
        tryOpenSchemes(button.urlSchemes, button: button, index: 0)
    }

    private func tryOpenSchemes(_ schemes: [String], button: OpenGameButton, index: Int) {
        guard index < schemes.count else {
            DispatchQueue.main.async {
                self.openGameWorking = nil
                self.log("\(button.name) — not installed")
            }
            return
        }
        guard let url = URL(string: schemes[index]) else {
            tryOpenSchemes(schemes, button: button, index: index + 1)
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                DispatchQueue.main.async { self.openGameWorking = nil }
            } else {
                self.tryOpenSchemes(schemes, button: button, index: index + 1)
            }
        }
    }
}
