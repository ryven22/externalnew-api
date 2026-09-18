import SwiftUI

// MARK: - Shared Models

struct InjectFileItem: Identifiable {
    let id = UUID()
    let targetPath: String
    let resourceFileName: String
    let resourceSubfolder: String
}

struct InjectButton: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let bundleID: String
    let targetPath: String
    let resourceFileName: String
    let resourceSubfolder: String
    var launchAfterInject: Bool = false
    var additionalFiles: [InjectFileItem] = []
    var isDeleteAction: Bool = false

    init(
        name: String,
        category: String,
        bundleID: String,
        targetPath: String,
        resourceFileName: String = "",
        resourceSubfolder: String = "",
        launchAfterInject: Bool = false,
        additionalFiles: [InjectFileItem] = [],
        isDeleteAction: Bool = false
    ) {
        self.name = name
        self.category = category
        self.bundleID = bundleID
        self.targetPath = targetPath
        self.resourceFileName = resourceFileName
        self.resourceSubfolder = resourceSubfolder
        self.launchAfterInject = launchAfterInject
        self.additionalFiles = additionalFiles
        self.isDeleteAction = isDeleteAction
    }

    var allFiles: [InjectFileItem] {
        var list = [
            InjectFileItem(
                targetPath: targetPath,
                resourceFileName: resourceFileName,
                resourceSubfolder: resourceSubfolder
            )
        ]
        list.append(contentsOf: additionalFiles)
        return list
    }
}

struct OpenGameButton: Identifiable {
    let id = UUID()
    let name: String
    let bundleID: String
    let urlSchemes: [String]
    let appStoreID: String
}

// MARK: - Shared Result & Error

enum InjectResult {
    case working
    case success
    case failed(String)
}

enum InjectError: LocalizedError {
    case containerNotFound(String)
    case renameFailed(String)
    var errorDescription: String? {
        switch self {
        case .containerNotFound(let id): return "App not found: \(id)"
        case .renameFailed(let reason): return "File replace failed: \(reason)"
        }
    }
}

// MARK: - Resolve container helper

func resolveContainer(bundleID: String) throws -> URL {
    guard let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID) else {
        throw InjectError.containerNotFound(bundleID)
    }
    return URL(fileURLWithPath: path, isDirectory: true)
}

// MARK: - Console View (Monochrome Basic)

// MARK: - Console View (Clean Minimalist Monochrome)

struct ConsoleView: View {
    let logs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Console topbar
            HStack(spacing: 8) {
                // Minimalist indicator dots
                Circle().fill(Color(white: 0.40)).frame(width: 5, height: 5)
                Circle().fill(Color(white: 0.25)).frame(width: 5, height: 5)
                Circle().fill(Color(white: 0.18)).frame(width: 5, height: 5)

                Text("TERMINAL")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(white: 0.50))
                    .kerning(1.2)

                Spacer()

                if !logs.isEmpty {
                    Text("\(logs.count) EVENTS")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.35))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(white: 0.05))
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1),
                alignment: .top
            )

            // Log lines
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        if logs.isEmpty {
                            HStack(spacing: 6) {
                                Text("$")
                                    .foregroundStyle(Color.white.opacity(0.40))
                                Text("ready — select an action")
                                    .foregroundStyle(Color(white: 0.35))
                            }
                            .font(.system(size: 11, design: .monospaced))
                        } else {
                            ForEach(Array(logs.enumerated()), id: \.offset) { i, line in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("$")
                                        .foregroundStyle(Color.white.opacity(0.45))
                                    Text(line)
                                        .foregroundStyle(Color(white: 0.85))
                                }
                                .font(.system(size: 11, design: .monospaced))
                                .id(i)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: logs.count) { _ in
                    if let last = logs.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            .frame(height: 110)
            .background(Color.black)
        }
    }
}

// MARK: - Inject Button Card (Clean Flat Monochrome)

struct InjectButtonCard: View {
    let button: InjectButton
    let result: InjectResult?
    let isWorking: Bool
    let progress: Double
    let onTap: () -> Void

    @State private var pressed = false

    var isSuccess: Bool {
        if case .success = result { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = result { return true }
        return false
    }

    var failedMessage: String? {
        if case .failed(let msg) = result { return msg }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main card row
                HStack(spacing: 12) {
                    // Left icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(white: 0.09))
                            .frame(width: 38, height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(isSuccess ? 0.30 : 0.12), lineWidth: 1)
                            )
                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSuccess ? .white : Color(white: 0.85))
                    }

                    // Name + Category
                    VStack(alignment: .leading, spacing: 3) {
                        Text(button.name)
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(.white)
                            .kerning(0.8)
                        Text(button.category)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(white: 0.40))
                            .kerning(1.2)
                    }

                    Spacer()

                    // Right status badge
                    statusBadge
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                // Linear progress bar
                if isWorking {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(white: 0.12))
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: geo.size.width * progress)
                                .animation(.linear(duration: 0.05), value: progress)
                        }
                    }
                    .frame(height: 2)
                }

                // Error message banner
                if let msg = failedMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.90))
                        Text(msg)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.80))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
            .background(Color(white: 0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSuccess
                            ? Color.white.opacity(0.35)
                            : (isWorking ? Color.white.opacity(0.40) : Color.white.opacity(0.12)),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .scaleEffect(pressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var iconName: String {
        if isWorking { return "arrow.triangle.2.circlepath" }
        if isSuccess { return "checkmark" }
        if isFailed  { return "xmark" }
        if button.isDeleteAction { return "trash.fill" }
        return "bolt.fill"
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isWorking {
            HStack(spacing: 5) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.55)
                    .tint(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(white: 0.12))
            .clipShape(Capsule())
        } else if isSuccess {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                Text("DONE")
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(0.8)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white)
            .clipShape(Capsule())
        } else if isFailed {
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                Text("FAIL")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.8)
            }
            .foregroundStyle(Color(white: 0.65))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(white: 0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        } else {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
                Text("APPLY")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(.white)
                    .kerning(1.0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(white: 0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
        }
    }
}

// MARK: - Open Game Button Card (Clean Flat Monochrome)

struct OpenGameButtonCard: View {
    let button: OpenGameButton
    let isWorking: Bool
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white)

                Text(button.name)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .kerning(0.5)

                Spacer()

                if isWorking {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.6)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(white: 0.45))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isWorking ? Color(white: 0.12) : Color(white: 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(isWorking ? 0.35 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
