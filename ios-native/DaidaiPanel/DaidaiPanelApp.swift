import SwiftUI

@main
struct DaidaiPanelApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var keychain = KeychainStorage.shared
    @StateObject private var navManager = NavigationManager()

    @State private var authViewModel: AuthViewModel?
    @State private var apiService: ApiService?
    @State private var isInitialized = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isInitialized, let authViewModel, let apiService {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(apiService)
                        .environmentObject(themeManager)
                        .environmentObject(keychain)
                        .environmentObject(navManager)
                } else {
                    LaunchScreen()
                }
            }
            .preferredColorScheme(themeManager.resolvedColorScheme)
            .task {
                await initializeApp()
            }
        }
    }

    private func initializeApp() async {
        let serverURL = keychain.serverURL ?? "http://localhost:9999"
        let api = ApiService(baseURL: serverURL, keychain: keychain)
        let auth = AuthViewModel(api: api, keychain: keychain)

        await MainActor.run {
            self.apiService = api
            self.authViewModel = auth
            self.isInitialized = true
        }

        await auth.restoreTrustedLocalSession()
    }
}

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            AppColors.primary.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "server.rack")
                    .font(.system(size: 64))
                    .foregroundColor(.white)
                Text("呆呆面板")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Daidai Panel")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var apiService: ApiService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var navManager: NavigationManager

    var body: some View {
        Group {
            switch authViewModel.state.status {
            case .unknown:
                BootPage()
            case .unauthenticated:
                if authViewModel.state.needsInit {
                    LoginPage()
                } else {
                    LoginPage()
                }
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.state.status)
    }
}
