import SwiftUI

struct SecurityView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = SecurityViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))

    var body: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                Picker("安全", selection: $viewModel.selectedTab) {
                    ForEach(SecurityViewModel.SecurityTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $viewModel.selectedTab) {
                    loginLogsTab.tag(SecurityViewModel.SecurityTab.loginLogs)
                    sessionsTab.tag(SecurityViewModel.SecurityTab.sessions)
                    ipWhitelistTab.tag(SecurityViewModel.SecurityTab.ipWhitelist)
                    twoFaTab.tag(SecurityViewModel.SecurityTab.twoFa)
                    auditLogsTab.tag(SecurityViewModel.SecurityTab.auditLogs)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle("安全设置")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.load()
        }
    }

    // MARK: - Login Logs

    private var loginLogsTab: some View {
        List {
            if viewModel.loginLogs.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无登录日志")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(viewModel.loginLogs.enumerated()), id: \.offset) { _, log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text((log["username"]?.value as? String) ?? "未知")
                                .font(.headline)
                            Spacer()
                            Text((log["ip"]?.value as? String) ?? "-")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Image(systemName: (log["success"]?.value as? Bool) == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor((log["success"]?.value as? Bool) == true ? AppColors.primary : AppColors.error)
                            Text((log["success"]?.value as? Bool) == true ? "成功" : "失败")
                                .font(.caption)
                            Spacer()
                            if let time = log["created_at"]?.value as? String {
                                Text(time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if let ua = log["user_agent"]?.value as? String {
                            Text(ua)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Sessions

    private var sessionsTab: some View {
        List {
            if viewModel.sessions.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无活跃会话")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(viewModel.sessions.enumerated()), id: \.offset) { index, session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text((session["ip"]?.value as? String) ?? "未知IP")
                                .font(.headline)
                            Text((session["user_agent"]?.value as? String) ?? "-")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if (session["is_current"]?.value as? Bool) == true {
                            Text("当前")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppColors.primary.opacity(0.15))
                                .foregroundColor(AppColors.primary)
                                .clipShape(Capsule())
                        } else {
                            Button("踢出") {
                                Task {
                                    if let sid = session["id"]?.value as? String {
                                        try? await viewModel.kickSession(sid)
                                    }
                                }
                            }
                            .font(.caption)
                            .foregroundColor(AppColors.error)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - IP Whitelist

    private var ipWhitelistTab: some View {
        List {
            Section {
                ForEach(viewModel.ipWhitelist, id: \.self) { ip in
                    HStack {
                        Text(ip)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Button {
                            Task { try? await viewModel.removeWhitelist(ip: ip) }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(AppColors.error)
                        }
                    }
                }
            } header: {
                Text("已添加的 IP")
            }

            Section {
                AddIPRow { ip in
                    Task { try? await viewModel.addWhitelist(ip: ip) }
                }
            } header: {
                Text("添加 IP")
            } footer: {
                Text("留空表示不限制 IP，添加后仅允许列表中的 IP 访问")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 2FA

    private var twoFaTab: some View {
        List {
            Section {
                HStack {
                    Text("状态")
                    Spacer()
                    Text(viewModel.twoFaEnabled ? "已启用" : "未启用")
                        .foregroundColor(viewModel.twoFaEnabled ? AppColors.primary : .secondary)
                }
            }

            if viewModel.twoFaEnabled {
                Section {
                    Button("关闭二步验证") {
                        Task { try? await viewModel.disable2Fa() }
                    }
                    .foregroundColor(AppColors.error)
                }
            } else {
                Section {
                    Button("开启二步验证") {
                        Task { await viewModel.setup2Fa() }
                    }
                    .foregroundColor(AppColors.primary)
                }

                if let setup = viewModel.twoFaSetupData {
                    Section("验证设置") {
                        if let secret = setup.secret {
                            HStack {
                                Text("密钥")
                                Spacer()
                                Text(secret)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                        TwoFaVerifyRow { code in
                            Task { try? await viewModel.verify2Fa(code: code) }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Audit Logs

    private var auditLogsTab: some View {
        List {
            if viewModel.auditLogs.isEmpty {
                HStack {
                    Spacer()
                    Text("暂无审计日志")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(viewModel.auditLogs.enumerated()), id: \.offset) { _, log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text((log["action"]?.value as? String) ?? "未知操作")
                                .font(.headline)
                            Spacer()
                            Text((log["username"]?.value as? String) ?? "-")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let detail = log["detail"]?.value as? String {
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        if let time = log["created_at"]?.value as? String {
                            Text(time)
                                .font(.caption2)
                                .foregroundColor(AppColors.slate400)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Add IP Row

struct AddIPRow: View {
    @State private var ip = ""
    let onAdd: (String) -> Void

    var body: some View {
        HStack {
            TextField("输入 IP 地址", text: $ip)
                .textContentType(.none)
                .autocapitalization(.none)
                .font(.system(.body, design: .monospaced))
            Button("添加") {
                guard !ip.isEmpty else { return }
                onAdd(ip)
                ip = ""
            }
            .disabled(ip.isEmpty)
            .foregroundColor(AppColors.primary)
        }
    }
}

// MARK: - 2FA Verify Row

struct TwoFaVerifyRow: View {
    @State private var code = ""
    let onVerify: (String) -> Void

    var body: some View {
        HStack {
            TextField("输入验证码", text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .font(.system(.body, design: .monospaced))
            Button("验证") {
                guard !code.isEmpty else { return }
                onVerify(code)
                code = ""
            }
            .disabled(code.count < 6)
            .foregroundColor(AppColors.primary)
        }
    }
}
