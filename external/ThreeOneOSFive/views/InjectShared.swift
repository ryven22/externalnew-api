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

struct ConsoleView: View {
    let logs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // console topbar
            HStack(spacing: 6) {
                // traffic lights (monochrome)
                Circle().fill(Color(white: 0.28)).frame(width: 7, height: 7)
                Circle().fill(Color(white: 0.22)).frame(width: 7, height: 7)
                Circle().fill(Color(white: 0.16)).frame(width: 7, height: 7)

                Rectangle()
                    .fill(Color(white: 0.14))
                    .frame(width: 1, height: 12)
                    .padding(.horizontal, 2)

                Image(systemName: "terminal.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.white.opacity(0.7))

                Text("console")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(white: 0.45))

                Spacer()

                if !logs.isEmpty {
                    Text("\(logs.count) lines")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(white: 0.35))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color(white: 0.05))
            .overlay(
                Rectangle()
                    .fill(Color(white: 0.16))
                    .frame(height: 1),
                alignment: .top
            )

            // log lines
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        if logs.isEmpty {
                            HStack(spacing: 6) {
                                Text(">")
                                    .foregroundStyle(Color.white.opacity(0.4))
                                Text("waiting for action...")
                                    .foregroundStyle(Color(white: 0.30))
                            }
                            .font(.system(size: 11, design: .monospaced))
                        } else {
                            ForEach(Array(logs.enumerated()), id: \.offset) { i, line in
                                HStack(alignment: .top, spacing: 6) {
                                    Text(">")
                                        .foregroundStyle(Color.white.opacity(0.5))
                                    Text(line)
                                        .foregroundStyle(Color(white: 0.70))
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
            .frame(height: 115)
            .background(Color(white: 0.03))
        }
    }
}

// MARK: - Inject Button Card (Black & White Basic Style)

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
                // main row
                HStack(spacing: 12) {
                    // left icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(iconBg)
                            .frame(width: 36, height: 36)
                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                    // name + category
                    VStack(alignment: .leading, spacing: 3) {
                        Text(button.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text(button.category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(white: 0.40))
                            .kerning(1)
                    }

                    Spacer()

                    // right status
                    statusBadge
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)

                // progress bar
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

                // error message
                if let msg = failedMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.8))
                        Text(msg)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            }
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
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
        return "bolt.fill"
    }

    private var iconColor: Color {
        if isSuccess { return .white }
        if isFailed  { return Color(white: 0.6) }
        return .white
    }

    private var iconBg: Color {
        if isSuccess { return Color(white: 0.18) }
        if isFailed  { return Color(white: 0.10) }
        if isWorking { return Color(white: 0.22) }
        return Color(white: 0.10)
    }

    private var cardBg: some View {
        LinearGradient(
            colors: [Color(white: 0.08), Color(white: 0.05)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        if isSuccess { return Color.white.opacity(0.40) }
        if isFailed  { return Color(white: 0.25) }
        if isWorking { return Color.white.opacity(0.50) }
        return Color(white: 0.14)
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
        } else if isSuccess {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 13))
                Text("DONE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .kerning(0.5)
            }
        } else if isFailed {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(white: 0.6))
                    .font(.system(size: 13))
                Text("FAIL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(white: 0.6))
                    .kerning(0.5)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.white)
                Text("TAP")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(white: 0.50))
                    .kerning(0.5)
            }
        }
    }
}

// MARK: - Open Game Button Card (Monochrome Basic)

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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                if isWorking {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.6)
                        .tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color(white: 0.45))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isWorking ? Color(white: 0.12) : Color(white: 0.07))
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isWorking ? Color.white.opacity(0.4) : Color(white: 0.14), lineWidth: 1)
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
        .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
        .scaleEffect(pressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
