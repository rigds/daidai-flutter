import Foundation

@MainActor
final class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
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
            let response: ApiResponse<[User]> = try await api.getUsers()
            self.users = response.data ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func create(username: String, password: String, role: String) async throws {
        let body: [String: Any] = ["username": username, "password": password, "role": role]
        let _: ApiResponse<User> = try await api.createUser(body)
        await load()
    }

    func update(_ id: Int, body: [String: Any]) async throws {
        let _: ApiResponse<User> = try await api.updateUser(id, body: body)
        await load()
    }

    func delete(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteUser(id)
        users.removeAll { $0.id == id }
    }

    func resetPassword(_ id: Int, password: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.resetUserPassword(id, password: password)
    }
}
