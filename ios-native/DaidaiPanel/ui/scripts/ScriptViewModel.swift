import Foundation

@MainActor
final class ScriptViewModel: ObservableObject {
    @Published var tree: [ScriptNodeData] = []
    @Published var fileContent: String = ""
    @Published var currentLanguage: String?
    @Published var currentPath: String?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var error: String?
    @Published var runOutput: String?

    private var api: ApiService

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    func loadTree() async {
        isLoading = true
        error = nil
        do {
            let response: ApiResponse<[ScriptNodeData]> = try await api.getScriptTree()
            self.tree = response.data ?? []
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func loadContent(path: String) async {
        isLoading = true
        error = nil
        currentPath = path
        do {
            let response: ApiResponse<ScriptContentData> = try await api.getScriptContent(path: path)
            if let data = response.data {
                self.fileContent = data.content
                self.currentLanguage = data.language
            }
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }

    func save() async {
        guard let path = currentPath else { return }
        isSaving = true
        error = nil
        do {
            let _: ApiResponse<EmptyData> = try await api.renameScript(from: path, to: path)
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isSaving = false
    }

    func upload(path: String, data: Data) async throws {
        let _: ApiResponse<EmptyData> = try await api.createDirectory(path: path)
        await loadTree()
    }

    func rename(from: String, to: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.renameScript(from: from, to: to)
        await loadTree()
    }

    func move(from: String, to: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.moveScript(from: from, to: to)
        await loadTree()
    }

    func copy(from: String, to: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.copyScript(from: from, to: to)
        await loadTree()
    }

    func delete(paths: [String]) async throws {
        let _: ApiResponse<EmptyData> = try await api.deleteScripts(paths: paths)
        await loadTree()
    }

    func createDirectory(path: String) async throws {
        let _: ApiResponse<EmptyData> = try await api.createDirectory(path: path)
        await loadTree()
    }

    func run(path: String, args: [String]? = nil) async {
        error = nil
        runOutput = nil
        do {
            let response: ApiResponse<ScriptRunData> = try await api.runScript(path: path, args: args)
            runOutput = "脚本已启动 (PID: \(response.data?.pid ?? 0))"
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
    }

    func format() async {
        guard let language = currentLanguage else { return }
        error = nil
        do {
            let response: ApiResponse<ScriptFormatData> = try await api.formatScript(code: fileContent, language: language)
            if let formatted = response.data?.formatted {
                self.fileContent = formatted
            }
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
    }
}
