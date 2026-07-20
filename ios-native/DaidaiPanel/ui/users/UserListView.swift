import SwiftUI

struct UserListView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = UserViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))
    @State private var showAddSheet = false
    @State private var editingUser: User?
    @State private var showDeleteConfirm = false
    @State private var userToDelete: User?
    @State private var showResetPassword = false
    @State private var userToReset: User?
    @State private var newPassword = ""

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.users.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.users.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
        }
        .navigationTitle("用户管理")
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
        .sheet(isPresented: $showAddSheet) {
            UserFormView(viewModel: viewModel)
        }
        .sheet(item: $editingUser) { user in
            UserFormView(viewModel: viewModel, user: user)
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let user = userToDelete {
                    Task { try? await viewModel.delete(user.id) }
                }
            }
        } message: {
            Text("确定要删除用户「\(userToDelete?.username ?? "")」吗？")
        }
        .alert("重置密码", isPresented: $showResetPassword) {
            SecureField("新密码", text: $newPassword)
            Button("取消", role: .cancel) { newPassword = "" }
            Button("确认") {
                if let user = userToReset, !newPassword.isEmpty {
                    Task { try? await viewModel.resetPassword(user.id, password: newPassword) }
                    newPassword = ""
                }
            }
        } message: {
            Text("为用户「\(userToReset?.username ?? "")」设置新密码")
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无用户")
                .font(.title3)
                .foregroundColor(.secondary)
            Button("添加用户") { showAddSheet = true }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var listView: some View {
        List {
            ForEach(viewModel.users) { user in
                UserRow(user: user)
                    .contextMenu {
                        Button { editingUser = user } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        Button {
                            userToReset = user
                            showResetPassword = true
                        } label: {
                            Label("重置密码", systemImage: "key.fill")
                        }
                        Divider()
                        Button(role: .destructive) {
                            userToDelete = user
                            showDeleteConfirm = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .onTapGesture { editingUser = user }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundColor(roleColor.opacity(0.6))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.username)
                        .font(.headline)
                    Text(roleLabel)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(roleColor.opacity(0.15))
                        .foregroundColor(roleColor)
                        .clipShape(Capsule())
                }
                if let lastLogin = user.lastLoginAt {
                    Text("最后登录: \(TimeUtils.formatRelative(lastLogin))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !user.enabled {
                Text("已禁用")
                    .font(.caption2)
                    .foregroundColor(AppColors.error)
            }
        }
        .padding(.vertical, 2)
        .opacity(user.enabled ? 1.0 : 0.6)
    }

    private var roleLabel: String {
        switch user.role {
        case "admin": return "管理员"
        case "operator": return "操作员"
        default: return "观察者"
        }
    }

    private var roleColor: Color {
        switch user.role {
        case "admin": return AppColors.primary
        case "operator": return AppColors.blue500
        default: return AppColors.slate500
        }
    }
}

// MARK: - User Form

struct UserFormView: View {
    @ObservedObject var viewModel: UserViewModel
    @Environment(\.dismiss) var dismiss

    var user: User?

    @State private var username = ""
    @State private var password = ""
    @State private var role = "viewer"
    @State private var enabled = true
    @State private var showError = false
    @State private var errorMessage = ""

    private let roles = ["admin", "operator", "viewer"]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("用户名", text: $username)
                        .autocapitalization(.none)
                    if user == nil {
                        SecureField("密码", text: $password)
                    }
                    Picker("角色", selection: $role) {
                        ForEach(roles, id: \.self) { r in
                            Text(roleLabel(r)).tag(r)
                        }
                    }
                    Toggle("启用", isOn: $enabled)
                }
            }
            .navigationTitle(user == nil ? "添加用户" : "编辑用户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(username.isEmpty || (user == nil && password.isEmpty))
                }
            }
            .onAppear { loadExisting() }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func roleLabel(_ r: String) -> String {
        switch r {
        case "admin": return "管理员"
        case "operator": return "操作员"
        default: return "观察者"
        }
    }

    private func loadExisting() {
        guard let u = user else { return }
        username = u.username
        role = u.role
        enabled = u.enabled
    }

    private func save() {
        Task {
            do {
                if let u = user {
                    try await viewModel.update(u.id, body: [
                        "username": username,
                        "role": role,
                        "enabled": enabled
                    ])
                } else {
                    try await viewModel.create(username: username, password: password, role: role)
                }
                dismiss()
            } catch {
                errorMessage = ApiUtils.extractErrorMessage(from: error)
                showError = true
            }
        }
    }
}
