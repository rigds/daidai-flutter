import Foundation

@MainActor
final class DepViewModel: ObservableObject {
    @Published var deps: [Dependency] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTab: DepTab = .nodejs

    private var api: ApiService

    enum DepTab: String, CaseIterable {
        case nodejs = "Node.js"
        case python = "Python"
    }

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    func load() async {
        isLoading = true
        error = nil
        let type = selectedTab == .nodejs ? "nodejs" : "python"
        do {
            let response: ApiResponse<PaginatedData<Dependency>> = try await api.getDeps(page: 1, pageSize: 100, type: type)
            self.deps = response.data?.items ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func filteredDeps() -> [Dependency] {
        deps
    }

    func install(name: String, version: String? = nil) async throws {
        let type = selectedTab == .nodejs ? "nodejs" : "python"
        var body: [String: Any] = ["name": name, "type": type]
        if let version, !version.isEmpty { body["version"] = version }
        let _: ApiResponse<Dependency> = try await api.createDep(body)
        await load()
    }

    func uninstall(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteDep(id)
        deps.removeAll { $0.id == id }
    }

    func reinstall(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.reinstallDep(id)
        await load()
    }

    func cancel(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.cancelDep(id)
        await load()
    }
}
