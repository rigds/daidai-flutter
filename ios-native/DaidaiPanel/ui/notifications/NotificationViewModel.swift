import Foundation

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var channels: [NotifyChannel] = []
    @Published var types: [NotifyTypeData] = []
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
            async let channelsResult: ApiResponse<[NotifyChannel]> = api.getNotifications()
            async let typesResult: ApiResponse<[NotifyTypeData]> = api.notificationTypes()
            let (channelsResp, typesResp) = try await (channelsResult, typesResult)
            self.channels = channelsResp.data ?? []
            self.types = typesResp.data ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func create(body: [String: Any]) async throws {
        let _: ApiResponse<NotifyChannel> = try await api.createNotification(body)
        await load()
    }

    func update(_ id: Int, body: [String: Any]) async throws {
        let _: ApiResponse<NotifyChannel> = try await api.updateNotification(id, body: body)
        await load()
    }

    func delete(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteNotification(id)
        channels.removeAll { $0.id == id }
    }

    func enable(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.enableNotification(id)
        await load()
    }

    func disable(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.disableNotification(id)
        await load()
    }

    func toggle(_ channel: NotifyChannel) async throws {
        if channel.enabled {
            try await disable(channel.id)
        } else {
            try await enable(channel.id)
        }
    }

    func test(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.testNotification(id)
    }
}
