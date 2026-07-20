import Foundation

@MainActor
final class OpenApiViewModel: ObservableObject {
    @Published var apps: [OpenApiAppData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentSecret: String?

    private var api: ApiService

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            let response: ApiResponse<[OpenApiAppData]> = try await api.getOpenApiApps()
            self.apps = response.data ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func create(name: String) async throws {
        let _: ApiResponse<OpenApiAppData> = try await api.createOpenApiApp(["name": name])
        await load()
    }

    func update(_ id: Int, body: [String: Any]) async throws {
        let _: ApiResponse<OpenApiAppData> = try await api.updateOpenApiApp(id, body: body)
        await load()
    }

    func delete(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteOpenApiApp(id)
        apps.removeAll { $0.id == id }
    }

    func enable(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.enableOpenApiApp(id)
        await load()
    }

    func disable(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.disableOpenApiApp(id)
        await load()
    }

    func toggle(_ app: OpenApiAppData) async throws {
        if app.enabled {
            try await disable(app.id)
        } else {
            try await enable(app.id)
        }
    }

    func resetSecret(_ id: Int) async throws {
        let response: ApiResponse<OpenApiSecretData> = try await api.resetOpenApiAppSecret(id)
        self.currentSecret = response.data?.secret
        await load()
    }

    func viewSecret(_ id: Int) async {
        do {
            let response: ApiResponse<OpenApiSecretData> = try await api.viewOpenApiAppSecret(id)
            self.currentSecret = response.data?.secret
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
    }
}
