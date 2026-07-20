import SwiftUI
import LocalAuthentication

struct AppLockSettingsView: View {
    @State private var lockEnabled = false
    @State private var lockType: LockType = .password
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var patternPoints: [Int] = []
    @State private var biometricEnabled = false
    @State private var showSetupSheet = false
    @State private var setupStep: SetupStep = .chooseType
    @State private var showError = false
    @State private var errorMessage = ""

    enum LockType: String, CaseIterable {
        case password = "密码"
        case pattern = "图案"
    }

    enum SetupStep {
        case chooseType, enterPassword, enterPattern
    }

    var body: some View {
        GlassScaffold {
            List {
                enableSection
                if lockEnabled {
                    lockTypeSection
                    biometricSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("应用锁")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSetupSheet) {
            setupSheet
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Enable Section

    private var enableSection: some View {
        Section {
            Toggle(isOn: $lockEnabled.animation()) {
                Label {
                    Text("启用应用锁")
                } icon: {
                    Image(systemName: "lock.fill")
                        .foregroundColor(AppColors.primary)
                }
            }
            .onChange(of: lockEnabled) { newValue in
                if newValue {
                    setupStep = .chooseType
                    showSetupSheet = true
                }
            }
        } header: {
            Text("基本设置")
        } footer: {
            Text("启用后每次打开应用需要验证身份")
        }
    }

    // MARK: - Lock Type Section

    private var lockTypeSection: some View {
        Section("解锁方式") {
            ForEach(LockType.allCases, id: \.self) { type in
                Button {
                    lockType = type
                    setupStep = type == .password ? .enterPassword : .enterPattern
                    showSetupSheet = true
                } label: {
                    HStack {
                        Image(systemName: type == .password ? "key.fill" : "square.grid.3x3.fill")
                            .foregroundColor(AppColors.primary)
                            .frame(width: 24)
                        Text(type.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if lockType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Biometric Section

    private var biometricSection: some View {
        Section {
            Toggle(isOn: $biometricEnabled) {
                Label {
                    Text("生物识别解锁")
                } icon: {
                    Image(systemName: biometricIcon)
                        .foregroundColor(AppColors.primary)
                }
            }
            .onChange(of: biometricEnabled) { newValue in
                if newValue {
                    authenticateBiometric { success in
                        if !success {
                            biometricEnabled = false
                        }
                    }
                }
            }
        } header: {
            Text("快捷解锁")
        } footer: {
            Text("使用 Face ID 或 Touch ID 快速解锁")
        }
    }

    private var biometricIcon: String {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            return "faceid"
        }
        return "touchid"
    }

    // MARK: - Setup Sheet

    @ViewBuilder
    private var setupSheet: some View {
        NavigationStack {
            Group {
                switch setupStep {
                case .chooseType:
                    chooseTypeView
                case .enterPassword:
                    enterPasswordView
                case .enterPattern:
                    enterPatternView
                }
            }
            .navigationTitle(setupTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showSetupSheet = false
                        if !lockEnabled { lockEnabled = false }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var setupTitle: String {
        switch setupStep {
        case .chooseType: return "选择解锁方式"
        case .enterPassword: return "设置密码"
        case .enterPattern: return "设置图案"
        }
    }

    private var chooseTypeView: some View {
        VStack(spacing: 24) {
            Text("请选择解锁方式")
                .font(.headline)
                .padding(.top, 20)

            ForEach(LockType.allCases, id: \.self) { type in
                Button {
                    lockType = type
                    setupStep = type == .password ? .enterPassword : .enterPattern
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: type == .password ? "key.fill" : "square.grid.3x3.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primary)
                            .frame(width: 44, height: 44)
                            .background(AppColors.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.rawValue)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(type == .password ? "使用数字或字母密码" : "使用手势图案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(AppColors.glassCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var enterPasswordView: some View {
        VStack(spacing: 20) {
            SecureField("输入密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)

            SecureField("确认密码", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)

            Button("确认") {
                guard password.count >= 4 else {
                    errorMessage = "密码至少需要4位"
                    showError = true
                    return
                }
                guard password == confirmPassword else {
                    errorMessage = "两次输入的密码不一致"
                    showError = true
                    return
                }
                showSetupSheet = false
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(password.isEmpty || confirmPassword.isEmpty)

            Spacer()
        }
        .padding()
    }

    private var enterPatternView: some View {
        VStack(spacing: 20) {
            Text("请绘制解锁图案")
                .font(.subheadline)
                .foregroundColor(.secondary)

            PatternLockView(points: $patternPoints)
                .frame(width: 240, height: 240)

            Button("确认") {
                guard patternPoints.count >= 4 else {
                    errorMessage = "图案至少需要连接4个点"
                    showError = true
                    return
                }
                showSetupSheet = false
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.primary)
            .disabled(patternPoints.count < 4)

            Spacer()
        }
        .padding()
    }

    private func authenticateBiometric(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "设备不支持生物识别"
            showError = true
            completion(false)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "验证身份以启用生物识别") { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}

// MARK: - Pattern Lock View

struct PatternLockView: View {
    @Binding var points: [Int]
    @State private var currentPoint: Int?
    @State private var touchLocation: CGPoint?

    private let gridSize = 3
    private let dotRadius: CGFloat = 12
    private let spacing: CGFloat = 70

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: (size.width - spacing * 2) / 2, y: (size.height - spacing * 2) / 2)
            let dotPositions = (0..<9).map { index in
                CGPoint(
                    x: origin.x + CGFloat(index % gridSize) * spacing,
                    y: origin.y + CGFloat(index / gridSize) * spacing
                )
            }

            // Draw connections
            for i in 0..<points.count - 1 {
                let from = dotPositions[points[i]]
                let to = dotPositions[points[i + 1]]
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                context.stroke(path, with: .color(AppColors.primary.opacity(0.6)), lineWidth: 3)
            }

            // Draw line to current touch
            if let current = currentPoint, let touch = touchLocation {
                let from = dotPositions[current]
                var path = Path()
                path.move(to: from)
                path.addLine(to: touch)
                context.stroke(path, with: .color(AppColors.primary.opacity(0.3)), lineWidth: 2)
            }

            // Draw dots
            for (index, pos) in dotPositions.enumerated() {
                let isSelected = points.contains(index)
                let rect = CGRect(x: pos.x - dotRadius, y: pos.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
                context.fill(Circle().path(in: rect), with: .color(isSelected ? AppColors.primary : AppColors.slate300))
                if isSelected {
                    context.fill(Circle().path(in: CGRect(x: pos.x - 4, y: pos.y - 4, width: 8, height: 8)), with: .color(.white))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let origin = CGPoint(x: (240 - spacing * 2) / 2, y: (240 - spacing * 2) / 2)
                    let col = Int(round((value.location.x - origin.x) / spacing))
                    let row = Int(round((value.location.y - origin.y) / spacing))
                    guard col >= 0, col < gridSize, row >= 0, row < gridSize else { return }
                    let index = row * gridSize + col
                    if !points.contains(index) {
                        points.append(index)
                        currentPoint = index
                    }
                    touchLocation = value.location
                }
                .onEnded { _ in
                    currentPoint = nil
                    touchLocation = nil
                }
        )
    }
}
