import SwiftUI

struct ScriptListView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = ScriptViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showCreateDirSheet = false
    @State private var newDirName = ""
    @State private var showDeleteConfirm = false
    @State private var pathsToDelete: [String] = []
    @State private var showRenameSheet = false
    @State private var renameTarget: String = ""
    @State private var renameNewName: String = ""
    @State private var showUploadSheet = false

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.tree.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.tree.isEmpty {
                    emptyView
                } else {
                    treeView
                }
            }
        }
        .navigationTitle("脚本管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showCreateDirSheet = true } label: {
                        Label("新建目录", systemImage: "folder.badge.plus")
                    }
                    Button { showUploadSheet = true } label: {
                        Label("上传文件", systemImage: "arrow.up.doc")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.loadTree()
        }
        .refreshable { await viewModel.loadTree() }
        .alert("新建目录", isPresented: $showCreateDirSheet) {
            TextField("目录名称", text: $newDirName)
            Button("取消", role: .cancel) { newDirName = "" }
            Button("创建") {
                Task {
                    try? await viewModel.createDirectory(path: newDirName)
                    newDirName = ""
                }
            }
        }
        .alert("重命名", isPresented: $showRenameSheet) {
            TextField("新名称", text: $renameNewName)
            Button("取消", role: .cancel) {}
            Button("确认") {
                Task {
                    let parent = (renameTarget as NSString).deletingLastPathComponent
                    let newPath = (parent as NSString).appendingPathComponent(renameNewName)
                    try? await viewModel.rename(from: renameTarget, to: newPath)
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task { try? await viewModel.delete(paths: pathsToDelete) }
            }
        } message: {
            Text("确定要删除选中的文件吗？此操作不可撤销。")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无脚本文件")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var treeView: some View {
        List {
            ForEach(viewModel.tree, id: \.path) { node in
                ScriptNodeRow(
                    node: node,
                    viewModel: viewModel,
                    onDelete: { paths in
                        pathsToDelete = paths
                        showDeleteConfirm = true
                    },
                    onRename: { path in
                        renameTarget = path
                        renameNewName = (path as NSString).lastPathComponent
                        showRenameSheet = true
                    }
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Script Node Row

struct ScriptNodeRow: View {
    let node: ScriptNodeData
    @ObservedObject var viewModel: ScriptViewModel
    let onDelete: ([String]) -> Void
    let onRename: (String) -> Void

    var body: some View {
        if node.isDir {
            DisclosureGroup {
                if let children = node.children {
                    ForEach(children, id: \.path) { child in
                        ScriptNodeRow(
                            node: child,
                            viewModel: viewModel,
                            onDelete: onDelete,
                            onRename: onRename
                        )
                    }
                }
            } label: {
                Label(node.name, systemImage: "folder.fill")
                    .foregroundColor(AppColors.blue500)
            }
            .contextMenu {
                Button { onRename(node.path) } label: {
                    Label("重命名", systemImage: "pencil")
                }
                Button(role: .destructive) { onDelete([node.path]) } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        } else {
            NavigationLink {
                ScriptViewView(viewModel: viewModel, filePath: node.path)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: fileIcon(for: node.name))
                        .foregroundColor(fileColor(for: node.name))
                        .frame(width: 20)
                    Text(node.name)
                        .font(.body)
                        .lineLimit(1)
                }
            }
            .contextMenu {
                Button { onRename(node.path) } label: {
                    Label("重命名", systemImage: "pencil")
                }
                Button {
                    UIPasteboard.general.string = node.path
                } label: {
                    Label("复制路径", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) { onDelete([node.path]) } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "sh", "bash": return "terminal.fill"
        case "py": return "text.word.spacing"
        case "js", "ts": return "curlybraces"
        case "json": return "doc.text"
        case "yaml", "yml": return "list.bullet.rectangle"
        case "md": return "doc.richtext"
        case "txt": return "doc.plaintext"
        default: return "doc.fill"
        }
    }

    private func fileColor(for name: String) -> Color {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "sh", "bash": return AppColors.primary
        case "py": return AppColors.blue500
        case "js", "ts": return AppColors.amber500
        case "json": return AppColors.purple500
        case "yaml", "yml": return AppColors.red500
        default: return AppColors.slate500
        }
    }
}
