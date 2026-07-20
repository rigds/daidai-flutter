import SwiftUI

struct BootPage: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var keychain: KeychainStorage
    @EnvironmentObject var themeManager: ThemeManager

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var spinnerOpacity: Double = 0
    @State private var statusText: String = ""

    var body: some View {
        ZStack {
            AppColors.primary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "server.rack")
                    .font(.system(size: 72))
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 8) {
                    Text("呆呆面板")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Daidai Panel")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(logoOpacity)

                Spacer()

                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .opacity(spinnerOpacity)

                    Text(statusText)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(spinnerOpacity)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                spinnerOpacity = 1.0
            }
        }
        .task {
            statusText = "正在检查服务器..."
            try? await Task.sleep(nanoseconds: 800_000_000)

            await proceedFromBoot()
        }
    }

    private func proceedFromBoot() async {
        if let serverURL = keychain.serverURL, !serverURL.isEmpty {
            statusText = "正在恢复会话..."
            await authViewModel.restoreTrustedLocalSession()
        } else {
            statusText = "请选择服务器..."
            try? await Task.sleep(nanoseconds: 500_000_000)
            authViewModel.state = AuthState(status: .unauthenticated)
        }
    }
}
