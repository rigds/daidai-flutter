import SwiftUI

struct OpenApiView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = OpenApiViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showAddSheet = false
    @State private var editingApp: OpenApiAppData?
    @State private var showDeleteConfirm = false
    @State private var appToDelete: OpenApiAppData?
    @State private var showSecretSheet = false
    @State private var secretTitle = ""
    @State private var newAppName = ""

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.apps.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.apps.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("Open API")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.load()
        }
        .refreshable { await viewModel.load() }
        .alert("创建应用", isPresented: $showAddSheet) {
            TextField("应用名称", text: $newAppName)
                .autocapitalization(.none)
            Button("取消", role: .cancel) { newAppName = "" }
            Button("创建") {
                let name = newAppName
                newAppName = ""
                Task { try? await viewModel.create(name: name) }
            }
            .disabled(newAppName.isEmpty)
        }
        .sheet(isPresented: $showSecretSheet) {
            secretSheet
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let app = appToDelete {
                    Task { try? await viewModel.delete(app.id) }
                }
            }
        } message: {
            Text("确定要删除应用「\(appToDelete?.name ?? "")」吗？相关密钥将同时失效。")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无 API 应用")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("创建应用") { showAddSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        List {
            ForEach(viewModel.apps) { app in
                OpenApiAppRow(app: app)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            appToDelete = app
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash.fill")
                        }
                        .tint(AppColors.error)

                        Button {
                            Task { try? await viewModel.toggle(app) }
                        } label: {
                            Label(app.enabled ? "禁用" : "启用",
                                  systemImage: app.enabled ? "pause.circle.fill" : "play.circle.fill")
                        }
                        .tint(app.enabled ? AppColors.warning : AppColors.primary)
                    }
                    .contextMenu {
                        Button {
                            Task {
                                await viewModel.viewSecret(app.id)
                                secretTitle = "查看密钥"
                                showSecretSheet = true
                            }
                        } label: {
                            Label("查看密钥", systemImage: "eye.fill")
                        }
                        Button {
                            Task {
                                try? await viewModel.resetSecret(app.id)
                                secretTitle = "新密钥"
                                showSecretSheet = true
                            }
                        } label: {
                            Label("重置密钥", systemImage: "arrow.clockwise")
                        }
                        Divider()
                        Button {
                            Task { try? await viewModel.toggle(app) }
                        } label: {
                            Label(app.enabled ? "禁用" : "启用", systemImage: app.enabled ? "pause" : "play")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var secretSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.primary)

                Text(secretTitle)
                    .font(.headline)

                if let secret = viewModel.currentSecret {
                    Text(secret)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(AppColors.termBg)
                        .foregroundColor(AppColors.termFg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .textSelection(.enabled)

                    Button("复制") {
                        UIPasteboard.general.string = secret
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                } else {
                    Text("无法获取密钥")
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("密钥")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showSecretSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - OpenAPI App Row

struct OpenApiAppRow: View {
    let app: OpenApiAppData

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.title3)
                .foregroundColor(AppColors.primary)
                .frame(width: 36, height: 36)
                .background(AppColors.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                if let date = app.createdAt {
                    Text("创建于 \(TimeUtils.formatRelative(date))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if app.enabled {
                Text("启用")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppColors.primary.opacity(0.15))
                    .foregroundColor(AppColors.primary)
                    .clipShape(Capsule())
            } else {
                Text("禁用")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppColors.disabled.opacity(0.15))
                    .foregroundColor(AppColors.disabled)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
