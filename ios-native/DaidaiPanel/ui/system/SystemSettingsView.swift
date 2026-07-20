import SwiftUI

struct SystemSettingsView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = SystemViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var concurrentTasks = 1
    @State private var logRetention = 30
    @State private var proxyUrl = ""
    @State private var dockerMirror = ""
    @State private var showSaveSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        GlassScaffold {
            List {
                taskSection
                logSection
                networkSection
                updateSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("系统设置")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.loadSettings()
            loadValues()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
            }
        }
        .alert("保存成功", isPresented: $showSaveSuccess) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("系统设置已更新")
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Task Section

    private var taskSection: some View {
        Section {
            Stepper("并发任务数: \(concurrentTasks)", value: $concurrentTasks, in: 1...20)
        } header: {
            Text("任务")
        } footer: {
            Text("同时执行的最大任务数量")
        }
    }

    // MARK: - Log Section

    private var logSection: some View {
        Section {
            Stepper("日志保留天数: \(logRetention)", value: $logRetention, in: 1...365)
        } header: {
            Text("日志")
        } footer: {
            Text("超过保留天数的日志将自动清理")
        }
    }

    // MARK: - Network Section

    private var networkSection: some View {
        Section {
            TextField("代理地址", text: $proxyUrl)
                .textContentType(.URL)
                .autocapitalization(.none)
            TextField("Docker 镜像加速", text: $dockerMirror)
                .textContentType(.URL)
                .autocapitalization(.none)
        } header: {
            Text("网络")
        } footer: {
            Text("代理格式: http://host:port")
        }
    }

    // MARK: - Update Section

    private var updateSection: some View {
        Section {
            Button {
                Task {
                    do {
                        let response: ApiResponse<UpdateData> = try await apiService.checkUpdate()
                        if let data = response.data, data.hasUpdate == true {
                            showSaveSuccess = true
                        } else {
                            errorMessage = "当前已是最新版本"
                            showError = true
                        }
                    } catch {
                        errorMessage = ApiUtils.extractErrorMessage(from: error)
                        showError = true
                    }
                }
            } label: {
                Label("检查更新", systemImage: "arrow.triangle.2.circlepath")
            }
        } header: {
            Text("面板更新")
        }
    }

    // MARK: - Helpers

    private func loadValues() {
        concurrentTasks = viewModel.concurrentTasks
        logRetention = viewModel.logRetention
        proxyUrl = viewModel.proxyUrl
        dockerMirror = viewModel.dockerMirror
    }

    private func save() {
        Task {
            do {
                try await viewModel.saveSettings([
                    "concurrent_tasks": concurrentTasks,
                    "log_retention_days": logRetention,
                    "proxy_url": proxyUrl,
                    "docker_mirror": dockerMirror
                ])
                showSaveSuccess = true
            } catch {
                errorMessage = ApiUtils.extractErrorMessage(from: error)
                showError = true
            }
        }
    }
}
