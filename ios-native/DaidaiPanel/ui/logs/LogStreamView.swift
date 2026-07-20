import SwiftUI

struct LogStreamView: View {
    let logId: Int
    @EnvironmentObject var apiService: ApiService
    @State private var log: TaskLog?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showRaw = false

    var body: some View {
        GlassScaffold {
            Group {
                if isLoading && log == nil {
                    VStack {
                        Spacer()
                        ProgressView("加载中...")
                        Spacer()
                    }
                } else if let log {
                    logContent(log)
                } else if let error {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.error.opacity(0.5))
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("重试") {
                            Task { await loadLog() }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("日志详情 #\(logId)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLog()
        }
        .refreshable {
            await loadLog()
        }
    }

    private func logContent(_ log: TaskLog) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                infoCard(log)
                contentCard(log)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func infoCard(_ log: TaskLog) -> some View {
        GlassCard(padding: 16) {
            VStack(spacing: 12) {
                HStack {
                    Text(log.taskName ?? "任务 #\(log.taskId)")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Spacer()
                    StatusBadge(status: statusType(for: log), size: .medium)
                }

                Divider()

                HStack(spacing: 20) {
                    detailItem(label: "状态", value: log.statusText)
                    detailItem(label: "耗时", value: log.durationText)
                }

                HStack(spacing: 20) {
                    detailItem(label: "开始时间", value: TimeUtils.formatTimeCn(log.startedAt))
                    if let endedAt = log.endedAt {
                        detailItem(label: "结束时间", value: TimeUtils.formatTimeCn(endedAt))
                    }
                }
            }
        }
    }

    private func contentCard(_ log: TaskLog) -> some View {
        GlassCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("执行输出", systemImage: "terminal")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = decodedContent(log.content)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                let content = decodedContent(log.content)
                if content.isEmpty {
                    Text("无输出内容")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(content)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func decodedContent(_ content: String) -> String {
        guard !content.isEmpty else { return "" }
        if let data = Data(base64Encoded: content.trimmingCharacters(in: .whitespacesAndNewlines)),
           let decoded = String(data: data, encoding: .utf8) {
            return decoded
        }
        return content
    }

    private func statusType(for log: TaskLog) -> StatusType {
        if log.isRunning { return .running }
        if log.isSuccess { return .success }
        if log.isFailed { return .failed }
        return .disabled
    }

    private func loadLog() async {
        isLoading = true
        error = nil
        do {
            let result: ApiResponse<TaskLog> = try await apiService.getLog(logId)
            self.log = result.data
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }
}
