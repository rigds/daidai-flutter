import Foundation

@MainActor
final class EnvViewModel: ObservableObject {
    @Published var envs: [EnvVar] = []
    @Published var isLoading = false
    @Published var keyword = ""
    @Published var selectedGroup = ""
    @Published var groups: [String] = []
    @Published var error: String?

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
            async let envsResult: ApiResponse<PaginatedData<EnvVar>> = api.getEnvs(
                page: 1,
                pageSize: 100,
                keyword: keyword.isEmpty ? nil : keyword,
                group: selectedGroup.isEmpty ? nil : selectedGroup
            )
            async let groupsResult: ApiResponse<[String]> = api.getEnvGroups()

            let (envsResponse, groupsResponse) = try await (envsResult, groupsResult)
            self.envs = envsResponse.data?.items ?? []
            self.groups = groupsResponse.data ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func createEnv(body: [String: Any]) async throws {
        let _: ApiResponse<EnvVar> = try await api.createEnv(body)
        await load()
    }

    func updateEnv(_ id: Int, body: [String: Any]) async throws {
        let _: ApiResponse<EnvVar> = try await api.updateEnv(id, body: body)
        await load()
    }

    func deleteEnv(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteEnv(id)
        envs.removeAll { $0.id == id }
    }

    func enableEnv(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.enableEnv(id)
        await load()
    }

    func disableEnv(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.disableEnv(id)
        await load()
    }

    func toggleEnv(_ env: EnvVar) async throws {
        if env.enabled {
            try await disableEnv(env.id)
        } else {
            try await enableEnv(env.id)
        }
    }

    func moveTop(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.moveTopEnv(id)
        await load()
    }

    func maskedValue(_ value: String) -> String {
        guard value.count > 4 else { return "****" }
        let prefix = value.prefix(2)
        let suffix = value.suffix(2)
        return "\(prefix)****\(suffix)"
    }
}
