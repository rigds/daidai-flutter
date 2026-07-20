import SwiftUI

struct DepListView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = DepViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showInstallAlert = false
    @State private var installName = ""
    @State private var installVersion = ""
    @State private var showUninstallConfirm = false
    @State private var depToUninstall: Dependency?

    var body: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                // Tab picker
                Picker("类型", selection: $viewModel.selectedTab) {
                    ForEach(DepViewModel.DepTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Group {
                    if viewModel.isLoading && viewModel.deps.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        listView
                    }
                }
            }
        }
        .navigationTitle("依赖管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showInstallAlert = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.load()
        }
        .refreshable { await viewModel.load() }
        .alert("安装依赖", isPresented: $showInstallAlert) {
            TextField("包名称", text: $installName)
                .autocapitalization(.none)
            TextField("版本 (可选)", text: $installVersion)
                .autocapitalization(.none)
            Button("取消", role: .cancel) {
                installName = ""
                installVersion = ""
            }
            Button("安装") {
                Task {
                    try? await viewModel.install(name: installName, version: installVersion)
                    installName = ""
                    installVersion = ""
                }
            }
        } message: {
            Text("输入要安装的\(viewModel.selectedTab.rawValue)包")
        }
        .alert("确认卸载", isPresented: $showUninstallConfirm) {
            Button("取消", role: .cancel) {}
            Button("卸载", role: .destructive) {
                if let dep = depToUninstall {
                    Task { try? await viewModel.uninstall(dep.id) }
                }
            }
        } message: {
            Text("确定要卸载「\(depToUninstall?.name ?? "")」吗？")
        }
    }

    private var listView: some View {
        let filtered = viewModel.filteredDeps()
        return List {
            if viewModel.selectedTab == .python {
                pythonRuntimeSection
            }

            if filtered.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无\(viewModel.selectedTab.rawValue)依赖")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(filtered) { dep in
                    DepRow(dep: dep)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                depToUninstall = dep
                                showUninstallConfirm = true
                            } label: {
                                Label("卸载", systemImage: "trash.fill")
                            }
                            .tint(AppColors.error)
                            .disabled(dep.isBusy)

                            Button {
                                Task { try? await viewModel.reinstall(dep.id) }
                            } label: {
                                Label("重装", systemImage: "arrow.clockwise")
                            }
                            .tint(AppColors.blue500)
                            .disabled(dep.isBusy)
                        }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var pythonRuntimeSection: some View {
        Section("Python 运行时") {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(AppColors.primary)
                Text("Python 环境管理")
                    .font(.subheadline)
                Spacer()
                Text("查看")
                    .font(.caption)
                    .foregroundColor(AppColors.blue500)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Dep Row

struct DepRow: View {
    let dep: Dependency

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dep.type == "nodejs" ? "cube.fill" : "text.word.spacing")
                .font(.title3)
                .foregroundColor(dep.isInstalled ? AppColors.primary : AppColors.disabled)
                .frame(width: 36, height: 36)
                .background((dep.isInstalled ? AppColors.primary : AppColors.disabled).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dep.name)
                        .font(.headline)
                    Text("@\(dep.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let remark = dep.remark, !remark.isEmpty {
                    Text(remark)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            StatusBadge(
                status: depStatusType,
                showIcon: dep.isBusy,
                size: .small
            )
        }
        .padding(.vertical, 2)
    }

    private var depStatusType: StatusType {
        if dep.isInstalling || dep.isRemoving { return .running }
        if dep.isQueued { return .queued }
        if dep.isFailed { return .failed }
        if dep.isCancelled { return .disabled }
        return .success
    }
}
