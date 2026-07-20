import Foundation

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
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
            let response: ApiResponse<PaginatedData<Subscription>> = try await api.getSubscriptions(page: 1, pageSize: 100)
            self.subscriptions = response.data?.items ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func create(body: [String: Any]) async throws {
        let _: ApiResponse<Subscription> = try await api.createSubscription(body)
        await load()
    }

    func update(_ id: Int, body: [String: Any]) async throws {
        let _: ApiResponse<Subscription> = try await api.updateSubscription(id, body: body)
        await load()
    }

    func delete(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteSubscription(id)
        subscriptions.removeAll { $0.id == id }
    }

    func enable(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.enableSubscription(id)
        await load()
    }

    func disable(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.disableSubscription(id)
        await load()
    }

    func pull(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.pullSubscription(id)
        await load()
    }

    func toggle(_ sub: Subscription) async throws {
        if sub.enabled {
            try await disable(sub.id)
        } else {
            try await enable(sub.id)
        }
    }
}
