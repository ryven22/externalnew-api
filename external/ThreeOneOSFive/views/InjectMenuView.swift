import SwiftUI

// MARK: - Target Game Enum

enum TargetGame: String, CaseIterable, Identifiable {
    case freefireTH = "com.dts.freefireth"
    case freefireMax = "com.dts.freefiremax"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freefireTH:  return "Free Fire"
        case .freefireMax: return "Free Fire MAX"
        }
    }

    var shortTag: String {
        switch self {
        case .freefireTH:  return "FF"
        case .freefireMax: return "FFM"
        }
    }

    var accentColor: Color {
        switch self {
        case .freefireTH:  return .white
        case .freefireMax: return Color(white: 0.85)
        }
    }
}

// MARK: - Inject Menu View (AIMBOT)

struct InjectMenuView: View {
    @State private var selectedTarget: TargetGame = .freefireTH
    @State private var results: [UUID: InjectResult] = [:]
    @State private var working: UUID? = nil
    @State private var progress: [UUID: Double] = [:]
    @State private var consoleLogs: [String] = []

    private func buttons(for target: TargetGame) -> [InjectButton] {
        switch target {
        case .freefireTH:
            return [
                InjectButton(
                    name: "AIMNECK",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceFileName: "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceSubfolder: "patches/aimneck risk free fire ori"
                ),
                InjectButton(
                    name: "AIMBODY",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceFileName: "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceSubfolder: "patches/aimbody risk free fire ori"
                ),
                InjectButton(
                    name: "AIMDRAG PRO SAFE",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.H5ak1JM1Eck~2FxRcJrEp~2FMzeuqmY~3D",
                    resourceFileName: "assetindexer.H5ak1JM1Eck~2FxRcJrEp~2FMzeuqmY~3D",
                    resourceSubfolder: "patches/aimdrag pro safe free fire ori"
                ),
            ]
        case .freefireMax:
            return [
                InjectButton(
                    name: "AIMNECK",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceFileName: "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceSubfolder: "patches/aimneck risk free fire max"
                ),
                InjectButton(
                    name: "AIMBODY",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceFileName: "cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                    resourceSubfolder: "patches/aimbody risk free fire max"
                ),
                InjectButton(
                    name: "AIMDRAG PRO SAFE",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/contentcache/Compulsory/ios/gameassetbundles/avatar/assetindexer.PENojQAQf9a1l6Dzjs0n1Z3rtVU~3D",
                    resourceFileName: "assetindexer.PENojQAQf9a1l6Dzjs0n1Z3rtVU~3D",
                    resourceSubfolder: "patches/aimdrag pro safe free fire max"
                ),
                InjectButton(
                    name: "ESP & AIMBOT",
                    category: "AIMBOT",
                    bundleID: target.rawValue,
                    targetPath: "Documents/Assembly-CSharp-patch.bytes",
                    resourceFileName: "Assembly-CSharp-patch.bytes",
                    resourceSubfolder: "patches/external esp",
                    additionalFiles: [
                        InjectFileItem(
                            targetPath: "Documents/localConfig.json",
                            resourceFileName: "localConfig.json",
                            resourceSubfolder: "patches/external esp"
                        )
                    ]
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

                // subtle top monochrome glow
                VStack {
                    RadialGradient(
                        colors: [Color(white: 0.10), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                    .frame(height: 220)
                    .offset(y: -40)
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            targetSelector
                            aimbotSection
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    }

                    ConsoleView(logs: consoleLogs)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        Text("AIMBOT")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                            .kerning(1.5)
                    }
                }
            }
            .onChange(of: selectedTarget) { _ in
                results = [:]
                working = nil
                progress = [:]
            }
        }
    }

    // MARK: - Target Selector

    private var targetSelector: some View {
        VStack(spacing: 8) {
            // Section label
            HStack {
                Text("TARGET APPLICATION")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(white: 0.45))
                    .kerning(1.5)
                Spacer()
            }
            .padding(.horizontal, 16)

            // Selector pills
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

            // Bundle ID badge
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

    // MARK: - Aimbot Section

    private var aimbotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // section header
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 3, height: 12)
                    .clipShape(Capsule())
                Text("AIMBOT")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .kerning(2)
                Rectangle()
                    .fill(Color(white: 0.16))
                    .frame(height: 1)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 10) {
                ForEach(buttons(for: selectedTarget)) { button in
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
    }

    // MARK: - Inject Logic

    private func inject(_ button: InjectButton) {
        guard working != button.id else { return }

        let filesToInject = button.allFiles
        let bundleBase = URL(fileURLWithPath: Bundle.main.bundlePath)

        // Pre-resolve all source URLs
        var resolvedFiles: [(source: URL, targetPath: String)] = []
        for item in filesToInject {
            let subfolderPath = bundleBase
                .appendingPathComponent(item.resourceSubfolder)
                .appendingPathComponent(item.resourceFileName)
            let sourceURL: URL? = {
                if FileManager.default.fileExists(atPath: subfolderPath.path) {
                    return subfolderPath
                }
                let rootPath = bundleBase.appendingPathComponent(item.resourceFileName)
                return FileManager.default.fileExists(atPath: rootPath.path) ? rootPath : nil
            }()

            guard let source = sourceURL else {
                results[button.id] = .failed("File not found: \(item.resourceFileName)")
                log("\(button.name) [\(selectedTarget.shortTag)] — inject error: \(item.resourceFileName) not found")
                return
            }
            resolvedFiles.append((source: source, targetPath: item.targetPath))
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
                for file in resolvedFiles {
                    let targetURL = containerURL.appendingPathComponent(file.targetPath)
                    let dir = targetURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    let data = try Data(contentsOf: file.source)
                    let staging = dir.appendingPathComponent(".regsxd-inject-\(UUID().uuidString)")
                    try data.write(to: staging, options: .atomic)
                    let renameResult = rename(staging.path, targetURL.path)
                    if renameResult != 0 {
                        let errMsg = String(cString: strerror(errno))
                        try? FileManager.default.removeItem(at: staging)
                        throw InjectError.renameFailed(errMsg)
                    }
                }
                await MainActor.run {
                    results[button.id] = .success
                    progress[button.id] = 1.0
                    working = nil
                    log("\(button.name) [\(tag)] — apply success (\(resolvedFiles.count) files)")
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
}
