import SwiftUI

struct LoginPage: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var keychain: KeychainStorage
    @EnvironmentObject var apiService: ApiService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navManager: NavigationManager

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var captcha: String = ""
    @State private var showPassword: Bool = false
    @State private var rememberPassword: Bool = false
    @State private var autoLogin: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showCaptcha: Bool = false
    @State private var needsInit: Bool = false
    @State private var initUsername: String = ""
    @State private var initPassword: String = ""
    @State private var initPasswordConfirm: String = ""
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0

    var body: some View {
        GlassScaffold {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    logoSection

                    if needsInit {
                        initAdminSection
                    } else {
                        loginSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            needsInit = authViewModel.state.needsInit
            loadSavedCredentials()
        }
        .alert("错误", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 56))
                .foregroundColor(AppColors.primary)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

            Text("呆呆面板")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(logoOpacity)

            Text("Daidai Panel")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(logoOpacity)
        }
    }

    // MARK: - Login

    private var loginSection: some View {
        GlassCard(cornerRadius: 20, padding: 24) {
            VStack(spacing: 20) {
                Text("登录")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                serverInfoBar

                VStack(spacing: 16) {
                    usernameField
                    passwordField

                    if showCaptcha {
                        captchaField
                    }
                }

                optionsRow

                if let error = errorMessage {
                    errorBanner(error)
                }

                loginButton

                if autoLogin {
                    Text("自动登录已开启")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var serverInfoBar: some View {
        HStack {
            Image(systemName: "server.rack")
                .font(.caption)
                .foregroundColor(AppColors.primary)
            Text(keychain.serverURL ?? "未配置服务器")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer()
            Button("切换") {
                navManager.navigate(to: .serverConfig)
            }
            .font(.caption)
            .foregroundColor(AppColors.primary)
        }
        .padding(10)
        .background(AppColors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var usernameField: some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField("用户名", text: $username)
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.glassBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.glassCardBorder, lineWidth: 0.5)
        )
    }

    private var passwordField: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(.secondary)
                .frame(width: 20)
            Group {
                if showPassword {
                    TextField("密码", text: $password)
                } else {
                    SecureField("密码", text: $password)
                }
            }
            .textContentType(.password)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.glassBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.glassCardBorder, lineWidth: 0.5)
        )
    }

    private var captchaField: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField("验证码", text: $captcha)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.glassBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.glassCardBorder, lineWidth: 0.5)
        )
    }

    private var optionsRow: some View {
        HStack {
            Toggle("记住密码", isOn: $rememberPassword)
                .font(.subheadline)
                .tint(AppColors.primary)
            Spacer()
            Toggle("自动登录", isOn: $autoLogin)
                .font(.subheadline)
                .tint(AppColors.primary)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.error)
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.error)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.red50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var loginButton: some View {
        Button {
            Task { await performLogin() }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "登录中..." : "登录")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading || username.isEmpty || password.isEmpty)
        .opacity((isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
    }

    // MARK: - Init Admin

    private var initAdminSection: some View {
        GlassCard(cornerRadius: 20, padding: 24) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primary)
                    Text("初始化管理员")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("首次使用，请创建管理员账号")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        TextField("管理员用户名", text: $initUsername)
                            .textContentType(.username)
                            .autocapitalization(.none)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.glassBg))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.glassCardBorder, lineWidth: 0.5))

                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        SecureField("密码", text: $initPassword)
                            .textContentType(.newPassword)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.glassBg))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.glassCardBorder, lineWidth: 0.5))

                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        SecureField("确认密码", text: $initPasswordConfirm)
                            .textContentType(.newPassword)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.glassBg))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.glassCardBorder, lineWidth: 0.5))
                }

                if let error = errorMessage {
                    errorBanner(error)
                }

                Button {
                    Task { await performInitAdmin() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "创建中..." : "创建管理员")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading || initUsername.isEmpty || initPassword.isEmpty)
                .opacity((isLoading || initUsername.isEmpty || initPassword.isEmpty) ? 0.6 : 1.0)
            }
        }
    }

    // MARK: - Actions

    private func performLogin() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authViewModel.login(
                username: username,
                password: password,
                captcha: showCaptcha ? captcha : nil
            )
            saveCredentials()
        } catch {
            let msg = ApiUtils.extractErrorMessage(from: error)
            if msg.contains("captcha") || msg.contains("验证码") {
                showCaptcha = true
            }
            errorMessage = msg
        }

        isLoading = false
    }

    private func performInitAdmin() async {
        guard initPassword == initPasswordConfirm else {
            errorMessage = "两次密码输入不一致"
            return
        }
        guard initPassword.count >= 6 else {
            errorMessage = "密码至少6位"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authViewModel.initAdmin(username: initUsername, password: initPassword)
        } catch {
            errorMessage = ApiUtils.extractErrorMessage(from: error)
        }

        isLoading = false
    }

    private func loadSavedCredentials() {
        // Load from UserDefaults for remember-password feature
        let defaults = UserDefaults.standard
        rememberPassword = defaults.bool(forKey: "remember_password")
        autoLogin = defaults.bool(forKey: "auto_login")
        if rememberPassword {
            username = defaults.string(forKey: "saved_username") ?? ""
            password = defaults.string(forKey: "saved_password") ?? ""
        }
    }

    private func saveCredentials() {
        let defaults = UserDefaults.standard
        defaults.set(rememberPassword, forKey: "remember_password")
        defaults.set(autoLogin, forKey: "auto_login")
        if rememberPassword {
            defaults.set(username, forKey: "saved_username")
            defaults.set(password, forKey: "saved_password")
        } else {
            defaults.removeObject(forKey: "saved_username")
            defaults.removeObject(forKey: "saved_password")
        }
    }
}
