import SwiftUI

struct ServerConfig: Codable, Identifiable, Equatable {
    var id: String { url }
    let name: String
    let url: String
    var isHealthy: Bool?

    static func == (lhs: ServerConfig, rhs: ServerConfig) -> Bool {
        lhs.url == rhs.url && lhs.name == rhs.name
    }
}

@MainActor
final class ServerConfigViewModel: ObservableObject {
    @Published var servers: [ServerConfig] = []
    @Published var isAdding: Bool = false
    @Published var newName: String = ""
    @Published var newURL: String = ""
    @Published var healthCheckResult: Bool?
    @Published var isChecking: Bool = false

    private let keychain: KeychainStorage

    init(keychain: KeychainStorage) {
        self.keychain = keychain
        loadServers()
    }

    func loadServers() {
        guard let json = keychain.panelsConfigJSON,
              let data = json.data(using: .utf8) else {
            servers = []
            return
        }
        servers = (try? JSONDecoder().decode([ServerConfig].self, from: data)) ?? []
    }

    func saveServers() {
        guard let data = try? JSONEncoder().encode(servers),
              let json = String(data: data, encoding: .utf8) else { return }
        keychain.panelsConfigJSON = json
    }

    func addServer() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        var url = newURL.trimmingCharacters(in: .whitespaces)
        if url.isEmpty { return }
        if !url.hasPrefix("http") { url = "http://\(url)" }
        if url.hasSuffix("/") { url = String(url.dropLast()) }

        let server = ServerConfig(name: name.isEmpty ? url : name, url: url)
        guard !servers.contains(where: { $0.url == server.url }) else { return }
        servers.append(server)
        saveServers()
        newName = ""
        newURL = ""
        isAdding = false
        healthCheckResult = nil
    }

    func deleteServer(at offsets: IndexSet) {
        servers.remove(atOffsets: offsets)
        saveServers()
    }

    func selectServer(_ server: ServerConfig) {
        keychain.serverURL = server.url
    }

    func healthCheck(url: String) async {
        var checkURL = url.trimmingCharacters(in: .whitespaces)
        if !checkURL.hasPrefix("http") { checkURL = "http://\(checkURL)" }
        if checkURL.hasSuffix("/") { checkURL = String(checkURL.dropLast()) }
        checkURL += "/api/system/health"

        isChecking = true
        healthCheckResult = nil

        guard let requestURL = URL(string: checkURL) else {
            healthCheckResult = false
            isChecking = false
            return
        }

        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 5
            let session = URLSession(configuration: config)
            let (_, response) = try await session.data(from: requestURL)
            if let httpResponse = response as? HTTPURLResponse {
                healthCheckResult = httpResponse.statusCode == 200
            } else {
                healthCheckResult = false
            }
        } catch {
            healthCheckResult = false
        }
        isChecking = false
    }
}

struct ServerConfigPage: View {
    @EnvironmentObject var keychain: KeychainStorage
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel: ServerConfigViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ServerConfigViewModel(keychain: KeychainStorage.shared))
    }

    var body: some View {
        GlassScaffold {
            VStack(spacing: 0) {
                if viewModel.servers.isEmpty && !viewModel.isAdding {
                    emptyState
                } else {
                    serverList
                }

                if viewModel.isAdding {
                    addServerSheet
                }
            }
        }
        .navigationTitle("服务器管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.isAdding.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isAdding ? "xmark" : "plus")
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary.opacity(0.5))
            Text("暂无服务器")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("点击右上角 + 添加服务器")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.tertiaryLabel))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var serverList: some View {
        List {
            Section {
                ForEach(viewModel.servers) { server in
                    ServerRow(server: server) {
                        viewModel.selectServer(server)
                        apiService.updateBaseURL(server.url)
                    }
                }
                .onDelete { offsets in
                    viewModel.deleteServer(at: offsets)
                }
            } header: {
                Text("已配置的服务器")
                    .font(.footnote)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var addServerSheet: some View {
        GlassCard(cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                Text("添加服务器")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("服务器名称")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("可选，如 生产环境", text: $viewModel.newName)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("服务器地址")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("http://example.com:9999", text: $viewModel.newURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        Button {
                            Task { await viewModel.healthCheck(url: viewModel.newURL) }
                        } label: {
                            if viewModel.isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "heart.text.square")
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .disabled(viewModel.newURL.isEmpty || viewModel.isChecking)
                    }

                    if let result = viewModel.healthCheckResult {
                        HStack(spacing: 4) {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result ? AppColors.success : AppColors.error)
                            Text(result ? "连接正常" : "连接失败")
                                .font(.caption)
                                .foregroundColor(result ? AppColors.success : AppColors.error)
                        }
                    }
                }

                HStack {
                    Button("取消") {
                        withAnimation {
                            viewModel.isAdding = false
                            viewModel.newName = ""
                            viewModel.newURL = ""
                            viewModel.healthCheckResult = nil
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)

                    Spacer()

                    Button("添加") {
                        withAnimation {
                            viewModel.addServer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.primary)
                    .disabled(viewModel.newURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ServerRow: View {
    let server: ServerConfig
    let onSelect: () -> Void

    @State private var isHealthy: Bool?
    @State private var isChecking = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: "server.rack")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(server.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(server.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                healthIndicator

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task {
            await checkHealth()
        }
    }

    @ViewBuilder
    private var healthIndicator: some View {
        if isChecking {
            ProgressView()
                .scaleEffect(0.7)
        } else if let healthy = isHealthy {
            Circle()
                .fill(healthy ? AppColors.success : AppColors.error)
                .frame(width: 8, height: 8)
        } else {
            Circle()
                .fill(AppColors.disabled)
                .frame(width: 8, height: 8)
        }
    }

    private func checkHealth() async {
        isChecking = true
        var url = server.url
        if url.hasSuffix("/") { url = String(url.dropLast()) }
        guard let requestURL = URL(string: "\(url)/api/system/health") else {
            isHealthy = false
            isChecking = false
            return
        }
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 5
            let session = URLSession(configuration: config)
            let (_, response) = try await session.data(from: requestURL)
            isHealthy = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            isHealthy = false
        }
        isChecking = false
    }
}
