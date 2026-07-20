import SwiftUI

struct AboutView: View {
    @EnvironmentObject var apiService: ApiService
    @State private var versionInfo: VersionData?
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        GlassScaffold {
            ScrollView {
                VStack(spacing: 24) {
                    appIconSection
                    versionSection
                    infoSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadVersion()
        }
    }

    private var appIconSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.primary)
                .frame(width: 100, height: 100)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Text("DaiDai Panel")
                .font(.title2)
                .fontWeight(.bold)

            Text("定时任务管理面板")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var versionSection: some View {
        GlassCard(padding: 16) {
            VStack(spacing: 12) {
                versionRow(label: "App 版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                versionRow(label: "Build 版本", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                if let info = versionInfo {
                    Divider()
                    versionRow(label: "服务端版本", value: info.version)
                    if let buildDate = info.buildDate {
                        versionRow(label: "构建日期", value: buildDate)
                    }
                }
            }
        }
    }

    private var infoSection: some View {
        GlassCard(padding: 16) {
            VStack(spacing: 12) {
                infoRow(icon: "gearshape.fill", label: "平台", value: "iOS")
                infoRow(icon: "iphone", label: "设备", value: UIDevice.current.model)
                infoRow(icon: "number", label: "系统版本", value: "iOS \(UIDevice.current.systemVersion)")
            }
        }
    }

    private func versionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AppColors.primary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func loadVersion() async {
        isLoading = true
        do {
            let result: ApiResponse<VersionData> = try await apiService.version()
            self.versionInfo = result.data
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }
}
