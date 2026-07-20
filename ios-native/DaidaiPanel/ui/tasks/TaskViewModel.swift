import Foundation

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var keyword = ""
    @Published var statusFilter: String = ""
    @Published var error: String?
    @Published var currentPage = 1
    @Published var totalTasks = 0
    @Published var hasMore = true

    private var api: ApiService
    private var loadTask: Task<Void, Never>?

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    var filteredTasks: [TaskItem] {
        tasks
    }

    func load() async {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            error = nil
            currentPage = 1

            do {
                let result: ApiResponse<PaginatedData<TaskItem>> = try await api.getTasks(
                    page: 1,
                    pageSize: 50,
                    keyword: keyword.isEmpty ? nil : keyword,
                    status: statusFilter.isEmpty ? nil : statusFilter
                )
                if !Task.isCancelled {
                    self.tasks = result.data?.items ?? []
                    self.totalTasks = result.data?.total ?? 0
                    self.hasMore = self.tasks.count < self.totalTasks
                }
            } catch {
                if !(error is CancellationError) {
                    self.error = ApiUtils.extractErrorMessage(from: error)
                }
            }
            isLoading = false
        }
        await loadTask?.value
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        let nextPage = currentPage + 1

        do {
            let result: ApiResponse<PaginatedData<TaskItem>> = try await api.getTasks(
                page: nextPage,
                pageSize: 50,
                keyword: keyword.isEmpty ? nil : keyword,
                status: statusFilter.isEmpty ? nil : statusFilter
            )
            let newTasks = result.data?.items ?? []
            self.tasks.append(contentsOf: newTasks)
            self.currentPage = nextPage
            self.hasMore = self.tasks.count < (result.data?.total ?? 0)
        } catch {}
    }

    func createTask(body: [String: Any]) async throws {
        let _: ApiResponse<TaskItem> = try await api.createTask(body)
        await load()
    }

    func updateTask(_ id: Int, body: [String: Any]) async throws {
        let _: ApiResponse<TaskItem> = try await api.updateTask(id, body: body)
        await load()
    }

    func deleteTask(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteTask(id)
        tasks.removeAll { $0.id == id }
        totalTasks -= 1
    }

    func runTask(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.runTask(id)
        await load()
    }

    func stopTask(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.stopTask(id)
        await load()
    }

    func enableTask(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.enableTask(id)
        await load()
    }

    func disableTask(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.disableTask(id)
        await load()
    }

    func pinTask(_ id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await api.pinTask(id)
        await load()
    }

    func batchRun(_ ids: [Int]) async throws {
        let _: ApiResponse<EmptyData> = try await api.batchRunTasks(ids)
        await load()
    }

    func batchDelete(_ ids: [Int]) async throws {
        let _: ApiResponse<EmptyData> = try await api.batchDeleteTasks(ids)
        await load()
    }

    func batchEnable(_ ids: [Int]) async throws {
        let _: ApiResponse<EmptyData> = try await api.batchEnableTasks(ids)
        await load()
    }

    func batchDisable(_ ids: [Int]) async throws {
        let _: ApiResponse<EmptyData> = try await api.batchDisableTasks(ids)
        await load()
    }

    func statusType(for task: TaskItem) -> StatusType {
        if task.isRunning { return .running }
        if task.isQueued { return .queued }
        if task.isEnabled { return .success }
        return .disabled
    }
}
