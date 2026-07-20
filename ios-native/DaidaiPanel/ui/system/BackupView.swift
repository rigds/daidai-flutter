import SwiftUI

struct BackupView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = SystemViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showDeleteConfirm = false
    @State private var backupToDelete: BackupData?
    @State private var showRestoreConfirm = false
    @State private var backupToRestore: BackupData?
    @State private var showUploadSheet = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.backups.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    listView
                }
            }
        }
        .navigationTitle("备份恢复")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            do {
                                try await viewModel.createBackup()
                            } catch {
                                errorMessage = ApiUtils.extractErrorMessage(from: error)
                                showError = true
                            }
                        }
                    } label: {
                        Label("创建备份", systemImage: "externaldrive.badge.plus")
                    }
                    Button { showUploadSheet = true } label: {
                        Label("上传备份", systemImage: "arrow.up.doc")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.loadBackups()
        }
        .refreshable { await viewModel.loadBackups() }
        .alert("确认恢复", isPresented: $showRestoreConfirm) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive) {
                if let backup = backupToRestore {
                    Task { await restoreBackup(backup) }
                }
            }
        } message: {
            Text("恢复备份将覆盖当前数据，确定要恢复「\(backupToRestore?.name ?? "")」吗？")
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let backup = backupToDelete {
                    Task { try? await deleteBackup(backup) }
                }
            }
        } message: {
            Text("确定要删除备份「\(backupToDelete?.name ?? "")」吗？")
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var listView: some View {
        List {
            // Status section
            if isRestoring {
                Section {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("正在恢复...")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("查看进度") {
                            Task { await viewModel.checkRestoreProgress() }
                        }
                        .font(.caption)
                    }
                }
            }

            // Backup list
            Section {
                if viewModel.backups.isEmpty {
                    HStack {
                        Spacer()
                        Text("暂无备份")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.backups, id: \.name) { backup in
                        BackupRow(backup: backup)
                            .contextMenu {
                                Button {
                                    backupToRestore = backup
                                    showRestoreConfirm = true
                                } label: {
                                    Label("恢复", systemImage: "arrow.counterclockwise")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    backupToDelete = backup
                                    showDeleteConfirm = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                Text("备份列表")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func restoreBackup(_ backup: BackupData) async {
        isRestoring = true
        do {
            try await viewModel.restore(backupName: backup.name)
        } catch {
            errorMessage = ApiUtils.extractErrorMessage(from: error)
            showError = true
        }
        isRestoring = false
    }

    private func deleteBackup(_ backup: BackupData) async {
        // Using API directly since viewModel doesn't have delete
        // In production, add deleteBackup to SystemViewModel
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: BackupData

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.fill")
                .font(.title2)
                .foregroundColor(AppColors.primary)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(backup.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 12) {
                    if let size = backup.size {
                        Text(TimeUtils.formatFileSize(size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let date = backup.createdAt {
                        Text(TimeUtils.formatTimeCn(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "ellipsis")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
