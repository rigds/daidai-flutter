import SwiftUI

struct PanelLogView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = SystemViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var searchText = ""
    @State private var levelFilter: String = ""

    private let levels = ["", "info", "warn", "error", "debug"]

    var body: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                // Filter bar
                HStack {
                    Picker("级别", selection: $levelFilter) {
                        Text("全部").tag("")
                        ForEach(levels.dropFirst(), id: \.self) { level in
                            Text(level.uppercased()).tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    TextField("搜索日志...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Log list
                Group {
                    if viewModel.isLoading && viewModel.logs.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredLogs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("暂无日志")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(filteredLogs.enumerated()), id: \.offset) { _, log in
                                    LogEntryRow(log: log)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle("面板日志")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.loadLogs()
        }
        .refreshable { await viewModel.loadLogs() }
    }

    private var filteredLogs: [[String: AnyCodable]] {
        viewModel.logs.filter { log in
            if !levelFilter.isEmpty {
                let level = (log["level"]?.value as? String)?.lowercased() ?? ""
                if level != levelFilter { return false }
            }
            if !searchText.isEmpty {
                let message = (log["message"]?.value as? String) ?? ""
                if !message.localizedCaseInsensitiveContains(searchText) { return false }
            }
            return true
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let log: [String: AnyCodable]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                levelBadge
                Spacer()
                if let time = log["created_at"]?.value as? String {
                    Text(time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            if let message = log["message"]?.value as? String {
                Text(parseAnsiColors(message))
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(AppColors.termBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var levelBadge: some View {
        let level = (log["level"]?.value as? String)?.uppercased() ?? "INFO"
        let color = levelColor(level)
        return Text(level)
            .font(.system(.caption2, design: .monospaced))
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "ERROR": return AppColors.termRed
        case "WARN": return AppColors.termYellow
        case "DEBUG": return AppColors.termCyan
        default: return AppColors.termGreen
        }
    }

    private func parseAnsiColors(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        result.foregroundColor = AppColors.termFg

        let pattern = "\\x1b\\[(\\d+)m"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }

        let nsString = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        var colorStack: [Color] = [AppColors.termFg]

        for match in matches {
            let code = nsString.substring(with: match.range(at: 1))
            let range = Range(match.range, in: text)

            if let attrRange = range.flatMap({ Range($0, in: result) }) {
                switch code {
                case "0": colorStack = [AppColors.termFg]
                case "31": colorStack.append(AppColors.termRed)
                case "32": colorStack.append(AppColors.termGreen)
                case "33": colorStack.append(AppColors.termYellow)
                case "34": colorStack.append(AppColors.termBlue)
                case "35": colorStack.append(AppColors.termMagenta)
                case "36": colorStack.append(AppColors.termCyan)
                default: break
                }
                result[attrRange].foregroundColor = colorStack.last ?? AppColors.termFg
                result[attrRange].backgroundColor = .clear
            }
        }

        return result
    }
}
