import Foundation

@MainActor
final class LogViewModel: ObservableObject {
    @Published var logs: [TaskLog] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 1
    @Published var totalLogs = 0
    @Published var hasMore = true
    @Published var selectedTaskId: Int?

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
        currentPage = 1

        do {
            let result: ApiResponse<PaginatedData<TaskLog>> = try await api.getLogs(
                taskId: selectedTaskId,
                page: 1,
                pageSize: 50
            )
            self.logs = result.data?.items ?? []
            self.totalLogs = result.data?.total ?? 0
            self.hasMore = self.logs.count < self.totalLogs
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        let nextPage = currentPage + 1

        do {
            let result: ApiResponse<PaginatedData<TaskLog>> = try await api.getLogs(
                taskId: selectedTaskId,
                page: nextPage,
                pageSize: 50
            )
            let newLogs = result.data?.items ?? []
            self.logs.append(contentsOf: newLogs)
            self.currentPage = nextPage
            self.hasMore = self.logs.count < (result.data?.total ?? 0)
        } catch {}
    }

    func deleteLog(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteLog(id)
        logs.removeAll { $0.id == id }
        totalLogs -= 1
    }

    func cleanLogs() async throws {
        let _: ApiResponse<EmptyData> = try await api.cleanLogs()
        logs.removeAll()
        totalLogs = 0
    }

    func statusType(for log: TaskLog) -> StatusType {
        if log.isRunning { return .running }
        if log.isSuccess { return .success }
        if log.isFailed { return .failed }
        return .disabled
    }
}
