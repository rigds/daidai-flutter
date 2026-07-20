import Foundation

final class ApiService: ObservableObject {
    private(set) var endpoints: ApiEndpoints
    private let interceptor: AuthInterceptor
    private let session: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            return DateParser.parse(dateString) ?? Date()
        }
        return d
    }()

    init(baseURL: String, keychain: KeychainStorage) {
        self.endpoints = ApiEndpoints(baseURL: baseURL)
        self.interceptor = AuthInterceptor(keychain: keychain)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    func updateBaseURL(_ url: String) {
        endpoints.updateBaseURL(url)
    }

    var authInterceptor: AuthInterceptor { interceptor }

    // MARK: - Core Request

    func request<T: Codable>(_ urlString: String, method: String = "GET", body: [String: Any]? = nil, queryItems: [URLQueryItem]? = nil) async throws -> ApiResponse<T> {
        guard var components = URLComponents(string: urlString) else { throw ApiError.invalidURL }
        if let queryItems { components.queryItems = queryItems }
        guard let url = components.url else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await interceptor.intercept(request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ApiError.invalidResponse }

        guard httpResponse.statusCode == 200 else {
            // Try to extract error message from server response
            let message: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                message = json["error"] as? String
                    ?? json["message"] as? String
                    ?? "请求失败 (\(httpResponse.statusCode))"
            } else {
                message = String(data: data, encoding: .utf8) ?? "请求失败 (\(httpResponse.statusCode))"
            }
            throw ApiError.serverError(httpResponse.statusCode, message)
        }

        do {
            return try decoder.decode(ApiResponse<T>.self, from: data)
        } catch {
            throw ApiError.decodingError(error)
        }
    }

    func requestRaw(_ urlString: String, method: String = "GET", body: [String: Any]? = nil, queryItems: [URLQueryItem]? = nil) async throws -> (Data, HTTPURLResponse) {
        guard var components = URLComponents(string: urlString) else { throw ApiError.invalidURL }
        if let queryItems { components.queryItems = queryItems }
        guard let url = components.url else { throw ApiError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await interceptor.intercept(request)
        guard let httpResponse = response as? HTTPURLResponse else { throw ApiError.invalidResponse }
        return (data, httpResponse)
    }

    func get<T: Codable>(_ urlString: String, queryItems: [URLQueryItem]? = nil) async throws -> ApiResponse<T> {
        try await request(urlString, method: "GET", queryItems: queryItems)
    }

    func post<T: Codable>(_ urlString: String, body: [String: Any]? = nil) async throws -> ApiResponse<T> {
        try await request(urlString, method: "POST", body: body)
    }

    func put<T: Codable>(_ urlString: String, body: [String: Any]? = nil) async throws -> ApiResponse<T> {
        try await request(urlString, method: "PUT", body: body)
    }

    func delete<T: Codable>(_ urlString: String, body: [String: Any]? = nil) async throws -> ApiResponse<T> {
        try await request(urlString, method: "DELETE", body: body)
    }

    // MARK: - Auth

    func checkInit() async throws -> ApiResponse<CheckInitData> {
        let (data, response) = try await requestRaw(endpoints.checkInit)
        guard response.statusCode == 200 else {
            throw ApiError.serverError(response.statusCode, "Check init failed")
        }
        // Server returns {"need_init": false} - parse directly
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let needInit = json["need_init"] as? Bool {
            // Wrap in ApiResponse format for compatibility
            let inner = CheckInitData(initialized: !needInit)
            return ApiResponse(code: 200, message: "ok", data: inner)
        }
        // Fallback: try standard ApiResponse decode
        return try decoder.decode(ApiResponse<CheckInitData>.self, from: data)
    }

    func initAdmin(username: String, password: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.initAdmin, body: ["username": username, "password": password])
    }

    func login(username: String, password: String, captcha: String? = nil) async throws -> ApiResponse<LoginData> {
        var body: [String: Any] = ["username": username, "password": password]
        if let captcha { body["captcha"] = captcha }
        return try await post(endpoints.login, body: body)
    }

    func logout() async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.logout)
    }

    func refreshToken(_ refreshToken: String) async throws -> ApiResponse<RefreshTokenData> {
        try await post(endpoints.refreshToken, body: ["refresh_token": refreshToken])
    }

    func getUser() async throws -> ApiResponse<User> {
        try await get(endpoints.getUser)
    }

    func changePassword(oldPassword: String, newPassword: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.changePassword, body: ["old_password": oldPassword, "new_password": newPassword])
    }

    func captchaConfig() async throws -> ApiResponse<CaptchaConfigData> {
        try await get(endpoints.captchaConfig)
    }

    // MARK: - System

    func health() async throws -> ApiResponse<EmptyData> {
        try await get(endpoints.health)
    }

    func version() async throws -> ApiResponse<VersionData> {
        try await get(endpoints.version)
    }

    func systemInfo() async throws -> ApiResponse<SystemInfoData> {
        try await get(endpoints.systemInfo)
    }

    func dashboard() async throws -> ApiResponse<DashboardData> {
        try await get(endpoints.dashboard)
    }

    func systemStats() async throws -> ApiResponse<SystemStatsData> {
        try await get(endpoints.systemStats)
    }

    func checkUpdate() async throws -> ApiResponse<UpdateData> {
        try await get(endpoints.checkUpdate)
    }

    func getPanelSettings() async throws -> ApiResponse<[String: AnyCodable]> {
        try await get(endpoints.panelSettings)
    }

    func updatePanelSettings(_ settings: [String: Any]) async throws -> ApiResponse<EmptyData> {
        try await put(endpoints.panelSettings, body: settings)
    }

    func getPanelLog(page: Int = 1, pageSize: Int = 50) async throws -> ApiResponse<PaginatedData<[String: AnyCodable]>> {
        try await get(endpoints.panelLog, queryItems: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ])
    }

    func sponsors() async throws -> ApiResponse<[String: AnyCodable]> {
        try await get(endpoints.sponsors)
    }

    func createBackup() async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.backup)
    }

    func getBackups() async throws -> ApiResponse<[BackupData]> {
        try await get(endpoints.backups)
    }

    func downloadBackup(name: String) async throws -> (Data, HTTPURLResponse) {
        try await requestRaw(endpoints.backupDownload(name))
    }

    func restore(backupName: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.restore, body: ["backup_name": backupName])
    }

    func restoreProgress() async throws -> ApiResponse<RestoreProgressData> {
        try await get(endpoints.restoreProgress)
    }

    // MARK: - Tasks

    func getTasks(page: Int = 1, pageSize: Int = 50, keyword: String? = nil, status: String? = nil, labels: String? = nil) async throws -> ApiResponse<PaginatedData<TaskItem>> {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ]
        if let keyword, !keyword.isEmpty { items.append(URLQueryItem(name: "keyword", value: keyword)) }
        if let status, !status.isEmpty { items.append(URLQueryItem(name: "status", value: status)) }
        if let labels, !labels.isEmpty { items.append(URLQueryItem(name: "labels", value: labels)) }
        return try await get(endpoints.tasks, queryItems: items)
    }

    func getTask(_ id: Int) async throws -> ApiResponse<TaskItem> {
        try await get(endpoints.task(id))
    }

    func createTask(_ body: [String: Any]) async throws -> ApiResponse<TaskItem> {
        try await post(endpoints.tasks, body: body)
    }

    func updateTask(_ id: Int, body: [String: Any]) async throws -> ApiResponse<TaskItem> {
        try await put(endpoints.task(id), body: body)
    }

    func deleteTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.task(id))
    }

    func runTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskRun(id))
    }

    func stopTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskStop(id))
    }

    func enableTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskEnable(id))
    }

    func disableTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskDisable(id))
    }

    func pinTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskPin(id))
    }

    func unpinTask(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskUnpin(id))
    }

    func copyTask(_ id: Int) async throws -> ApiResponse<TaskItem> {
        try await post(endpoints.taskCopy(id))
    }

    func taskLatestLog(_ id: Int) async throws -> ApiResponse<TaskLog> {
        try await get(endpoints.taskLatestLog(id))
    }

    func taskLogFiles(_ id: Int) async throws -> ApiResponse<[TaskLogFileData]> {
        try await get(endpoints.taskLogFiles(id))
    }

    func taskStats() async throws -> ApiResponse<TaskStatsData> {
        try await get(endpoints.taskStats)
    }

    func batchEnableTasks(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskBatchEnable, body: ["ids": ids])
    }

    func batchDisableTasks(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskBatchDisable, body: ["ids": ids])
    }

    func batchRunTasks(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskBatchRun, body: ["ids": ids])
    }

    func batchDeleteTasks(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskBatchDelete, body: ["ids": ids])
    }

    func cleanTaskLogs(beforeDate: String? = nil) async throws -> ApiResponse<EmptyData> {
        var body: [String: Any] = [:]
        if let beforeDate { body["before_date"] = beforeDate }
        return try await post(endpoints.taskCleanLogs, body: body.isEmpty ? nil : body)
    }

    func exportTasks() async throws -> (Data, HTTPURLResponse) {
        try await requestRaw(endpoints.taskExport)
    }

    func importTasks(data: [String: Any]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.taskImport, body: data)
    }

    func cronParse(expression: String) async throws -> ApiResponse<CronParseData> {
        try await post(endpoints.cronParse, body: ["expression": expression])
    }

    func cronTemplates() async throws -> ApiResponse<[CronTemplateData]> {
        try await get(endpoints.cronTemplates)
    }

    // MARK: - Logs

    func getLogs(taskId: Int? = nil, page: Int = 1, pageSize: Int = 50, status: String? = nil) async throws -> ApiResponse<PaginatedData<TaskLog>> {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ]
        if let taskId { items.append(URLQueryItem(name: "task_id", value: "\(taskId)")) }
        if let status { items.append(URLQueryItem(name: "status", value: status)) }
        return try await get(endpoints.logs, queryItems: items)
    }

    func getLog(_ id: Int) async throws -> ApiResponse<TaskLog> {
        try await get(endpoints.log(id))
    }

    func deleteLog(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.log(id))
    }

    func batchDeleteLogs(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.logBatchDelete, body: ["ids": ids])
    }

    func cleanLogs(beforeDate: String? = nil) async throws -> ApiResponse<EmptyData> {
        var body: [String: Any] = [:]
        if let beforeDate { body["before_date"] = beforeDate }
        return try await post(endpoints.logClean, body: body.isEmpty ? nil : body)
    }

    // MARK: - Scripts

    func getScriptTree(path: String? = nil) async throws -> ApiResponse<[ScriptNodeData]> {
        var items: [URLQueryItem] = []
        if let path { items.append(URLQueryItem(name: "path", value: path)) }
        return try await get(endpoints.scriptTree, queryItems: items)
    }

    func getScriptContent(path: String) async throws -> ApiResponse<ScriptContentData> {
        try await get(endpoints.scriptContent, queryItems: [URLQueryItem(name: "path", value: path)])
    }

    func createDirectory(path: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptDirectory, body: ["path": path])
    }

    func renameScript(from: String, to: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptRename, body: ["from": from, "to": to])
    }

    func moveScript(from: String, to: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptMove, body: ["from": from, "to": to])
    }

    func copyScript(from: String, to: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptCopy, body: ["from": from, "to": to])
    }

    func deleteScripts(paths: [String]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptBatch, body: ["action": "delete", "paths": paths])
    }

    func runScript(path: String, args: [String]? = nil) async throws -> ApiResponse<ScriptRunData> {
        var body: [String: Any] = ["path": path]
        if let args { body["args"] = args }
        return try await post(endpoints.scriptRun, body: body)
    }

    func runCode(code: String, language: String) async throws -> ApiResponse<ScriptRunData> {
        try await post(endpoints.scriptRunCode, body: ["code": code, "language": language])
    }

    func getScriptRunLogs() async throws -> ApiResponse<[ScriptRunLogData]> {
        try await get(endpoints.scriptRunLogs)
    }

    func stopScriptRun(_ id: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptRunStop, body: ["id": id])
    }

    func clearScriptRunLogs() async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.scriptRunClear)
    }

    func formatScript(code: String, language: String) async throws -> ApiResponse<ScriptFormatData> {
        try await post(endpoints.scriptFormat, body: ["code": code, "language": language])
    }

    // MARK: - Envs

    func getEnvs(page: Int = 1, pageSize: Int = 100, keyword: String? = nil, group: String? = nil) async throws -> ApiResponse<PaginatedData<EnvVar>> {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ]
        if let keyword, !keyword.isEmpty { items.append(URLQueryItem(name: "keyword", value: keyword)) }
        if let group, !group.isEmpty { items.append(URLQueryItem(name: "group", value: group)) }
        return try await get(endpoints.envs, queryItems: items)
    }

    func getEnv(_ id: Int) async throws -> ApiResponse<EnvVar> {
        try await get(endpoints.env(id))
    }

    func createEnv(_ body: [String: Any]) async throws -> ApiResponse<EnvVar> {
        try await post(endpoints.envs, body: body)
    }

    func updateEnv(_ id: Int, body: [String: Any]) async throws -> ApiResponse<EnvVar> {
        try await put(endpoints.env(id), body: body)
    }

    func deleteEnv(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.env(id))
    }

    func enableEnv(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envEnable(id))
    }

    func disableEnv(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envDisable(id))
    }

    func moveTopEnv(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envMoveTop(id))
    }

    func cancelTopEnv(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envCancelTop(id))
    }

    func batchEnableEnvs(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envBatchEnable, body: ["ids": ids])
    }

    func batchDisableEnvs(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envBatchDisable, body: ["ids": ids])
    }

    func batchDeleteEnvs(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envBatchDelete, body: ["ids": ids])
    }

    func getEnvGroups() async throws -> ApiResponse<[String]> {
        try await get(endpoints.envGroups)
    }

    func exportEnvs() async throws -> (Data, HTTPURLResponse) {
        try await requestRaw(endpoints.envExport)
    }

    func importEnvs(data: [String: Any]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.envImport, body: data)
    }

    // MARK: - Subscriptions

    func getSubscriptions(page: Int = 1, pageSize: Int = 50) async throws -> ApiResponse<PaginatedData<Subscription>> {
        try await get(endpoints.subscriptions, queryItems: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ])
    }

    func getSubscription(_ id: Int) async throws -> ApiResponse<Subscription> {
        try await get(endpoints.subscription(id))
    }

    func createSubscription(_ body: [String: Any]) async throws -> ApiResponse<Subscription> {
        try await post(endpoints.subscriptions, body: body)
    }

    func updateSubscription(_ id: Int, body: [String: Any]) async throws -> ApiResponse<Subscription> {
        try await put(endpoints.subscription(id), body: body)
    }

    func deleteSubscription(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.subscription(id))
    }

    func enableSubscription(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.subscriptionEnable(id))
    }

    func disableSubscription(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.subscriptionDisable(id))
    }

    func pullSubscription(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.subscriptionPull(id))
    }

    func pullStopSubscription(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.subscriptionPullStop(id))
    }

    func batchDeleteSubscriptions(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.subscriptionBatchDelete, body: ["ids": ids])
    }

    // MARK: - Notifications

    func getNotifications() async throws -> ApiResponse<[NotifyChannel]> {
        try await get(endpoints.notifications)
    }

    func getNotification(_ id: Int) async throws -> ApiResponse<NotifyChannel> {
        try await get(endpoints.notification(id))
    }

    func createNotification(_ body: [String: Any]) async throws -> ApiResponse<NotifyChannel> {
        try await post(endpoints.notifications, body: body)
    }

    func updateNotification(_ id: Int, body: [String: Any]) async throws -> ApiResponse<NotifyChannel> {
        try await put(endpoints.notification(id), body: body)
    }

    func deleteNotification(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.notification(id))
    }

    func enableNotification(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.notificationEnable(id))
    }

    func disableNotification(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.notificationDisable(id))
    }

    func testNotification(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.notificationTest(id))
    }

    func notificationTypes() async throws -> ApiResponse<[NotifyTypeData]> {
        try await get(endpoints.notificationTypes)
    }

    func sendNotification(title: String, content: String, channelId: Int? = nil) async throws -> ApiResponse<EmptyData> {
        var body: [String: Any] = ["title": title, "content": content]
        if let channelId { body["channel_id"] = channelId }
        return try await post(endpoints.notificationSend, body: body)
    }

    // MARK: - Dependencies

    func getDeps(page: Int = 1, pageSize: Int = 50, type: String? = nil) async throws -> ApiResponse<PaginatedData<Dependency>> {
        var items = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ]
        if let type { items.append(URLQueryItem(name: "type", value: type)) }
        return try await get(endpoints.deps, queryItems: items)
    }

    func getDep(_ id: Int) async throws -> ApiResponse<Dependency> {
        try await get(endpoints.dep(id))
    }

    func createDep(_ body: [String: Any]) async throws -> ApiResponse<Dependency> {
        try await post(endpoints.deps, body: body)
    }

    func deleteDep(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.dep(id))
    }

    func depStatus(_ id: Int) async throws -> ApiResponse<Dependency> {
        try await get(endpoints.depStatus(id))
    }

    func reinstallDep(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.depReinstall(id))
    }

    func cancelDep(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.depCancel(id))
    }

    func batchDeleteDeps(_ ids: [Int]) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.depBatchDelete, body: ["ids": ids])
    }

    func depPip(command: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.depPip, body: ["command": command])
    }

    func depNpm(command: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.depNpm, body: ["command": command])
    }

    func depMirrors() async throws -> ApiResponse<[MirrorData]> {
        try await get(endpoints.depMirrors)
    }

    func pythonRuntimes() async throws -> ApiResponse<[PythonRuntimeData]> {
        try await get(endpoints.depPythonRuntimes)
    }

    func pythonRuntimeDefault() async throws -> ApiResponse<PythonRuntimeData> {
        try await get(endpoints.depPythonRuntimeDefault)
    }

    // MARK: - Users

    func getUsers() async throws -> ApiResponse<[User]> {
        try await get(endpoints.users)
    }

    func getUser(_ id: Int) async throws -> ApiResponse<User> {
        try await get(endpoints.user(id))
    }

    func createUser(_ body: [String: Any]) async throws -> ApiResponse<User> {
        try await post(endpoints.users, body: body)
    }

    func updateUser(_ id: Int, body: [String: Any]) async throws -> ApiResponse<User> {
        try await put(endpoints.user(id), body: body)
    }

    func deleteUser(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.user(id))
    }

    func resetUserPassword(_ id: Int, password: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.userResetPassword(id), body: ["password": password])
    }

    // MARK: - Security

    func getLoginLogs(page: Int = 1, pageSize: Int = 50) async throws -> ApiResponse<PaginatedData<[String: AnyCodable]>> {
        try await get(endpoints.loginLogs, queryItems: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ])
    }

    func getSessions() async throws -> ApiResponse<[[String: AnyCodable]]> {
        try await get(endpoints.sessions)
    }

    func getIpWhitelist() async throws -> ApiResponse<[String]> {
        try await get(endpoints.ipWhitelist)
    }

    func updateIpWhitelist(_ ips: [String]) async throws -> ApiResponse<EmptyData> {
        try await put(endpoints.ipWhitelist, body: ["ips": ips])
    }

    func getAuditLogs(page: Int = 1, pageSize: Int = 50) async throws -> ApiResponse<PaginatedData<[String: AnyCodable]>> {
        try await get(endpoints.auditLogs, queryItems: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ])
    }

    func getLoginStats() async throws -> ApiResponse<[String: AnyCodable]> {
        try await get(endpoints.loginStats)
    }

    func twoFaSetup() async throws -> ApiResponse<TwoFaSetupData> {
        try await post(endpoints.twoFaSetup)
    }

    func twoFaVerify(code: String) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.twoFaVerify, body: ["code": code])
    }

    func twoFaStatus() async throws -> ApiResponse<TwoFaStatusData> {
        try await get(endpoints.twoFaStatus)
    }

    // MARK: - Configs

    func getConfigs() async throws -> ApiResponse<[String: AnyCodable]> {
        try await get(endpoints.configs)
    }

    func getConfig(_ key: String) async throws -> ApiResponse<AnyCodable> {
        try await get(endpoints.config(key))
    }

    func updateConfig(_ key: String, value: Any) async throws -> ApiResponse<EmptyData> {
        try await put(endpoints.config(key), body: ["value": value])
    }

    func batchUpdateConfigs(_ configs: [String: Any]) async throws -> ApiResponse<EmptyData> {
        try await put(endpoints.configBatch, body: ["configs": configs])
    }

    // MARK: - OpenAPI Apps

    func getOpenApiApps() async throws -> ApiResponse<[OpenApiAppData]> {
        try await get(endpoints.openApiApps)
    }

    func getOpenApiApp(_ id: Int) async throws -> ApiResponse<OpenApiAppData> {
        try await get(endpoints.openApiApp(id))
    }

    func createOpenApiApp(_ body: [String: Any]) async throws -> ApiResponse<OpenApiAppData> {
        try await post(endpoints.openApiApps, body: body)
    }

    func updateOpenApiApp(_ id: Int, body: [String: Any]) async throws -> ApiResponse<OpenApiAppData> {
        try await put(endpoints.openApiApp(id), body: body)
    }

    func deleteOpenApiApp(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await delete(endpoints.openApiApp(id))
    }

    func enableOpenApiApp(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.openApiAppEnable(id))
    }

    func disableOpenApiApp(_ id: Int) async throws -> ApiResponse<EmptyData> {
        try await post(endpoints.openApiAppDisable(id))
    }

    func resetOpenApiAppSecret(_ id: Int) async throws -> ApiResponse<OpenApiSecretData> {
        try await post(endpoints.openApiAppResetSecret(id))
    }

    func viewOpenApiAppSecret(_ id: Int) async throws -> ApiResponse<OpenApiSecretData> {
        try await get(endpoints.openApiAppViewSecret(id))
    }

    func getOpenApiAppLogs(_ id: Int, page: Int = 1, pageSize: Int = 50) async throws -> ApiResponse<PaginatedData<[String: AnyCodable]>> {
        try await get(endpoints.openApiAppLogs(id), queryItems: [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
        ])
    }
}

// MARK: - Auxiliary Data Types

struct CheckInitData: Codable {
    let initialized: Bool
}

struct LoginData: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct RefreshTokenData: Codable {
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct CaptchaConfigData: Codable {
    let enabled: Bool
    let type: String?
}

struct VersionData: Codable {
    let version: String
    let buildDate: String?

    enum CodingKeys: String, CodingKey {
        case version
        case buildDate = "build_date"
    }
}

struct SystemInfoData: Codable {
    let hostname: String?
    let os: String?
    let arch: String?
    let cpuUsage: Double?
    let memoryUsage: Double?
    let memoryTotal: Int64?
    let memoryUsed: Int64?
    let diskUsage: Double?
    let diskTotal: Int64?
    let diskUsed: Int64?
    let uptime: Int64?

    enum CodingKeys: String, CodingKey {
        case hostname, os, arch
        case cpuUsage = "cpu_usage"
        case memoryUsage = "memory_usage"
        case memoryTotal = "memory_total"
        case memoryUsed = "memory_used"
        case diskUsage = "disk_usage"
        case diskTotal = "disk_total"
        case diskUsed = "disk_used"
        case uptime
    }
}

struct DashboardData: Codable {
    let taskCount: Int?
    let runningTaskCount: Int?
    let enabledTaskCount: Int?
    let disabledTaskCount: Int?
    let todayRunCount: Int?
    let todayFailCount: Int?
    let depCount: Int?
    let envCount: Int?
    let subscriptionCount: Int?
    let systemInfo: SystemInfoData?

    enum CodingKeys: String, CodingKey {
        case taskCount = "task_count"
        case runningTaskCount = "running_task_count"
        case enabledTaskCount = "enabled_task_count"
        case disabledTaskCount = "disabled_task_count"
        case todayRunCount = "today_run_count"
        case todayFailCount = "today_fail_count"
        case depCount = "dep_count"
        case envCount = "env_count"
        case subscriptionCount = "subscription_count"
        case systemInfo = "system_info"
    }
}

struct SystemStatsData: Codable {
    let totalTasks: Int?
    let totalRuns: Int?
    let successRuns: Int?
    let failedRuns: Int?
    let recentLogs: [TaskLog]?

    enum CodingKeys: String, CodingKey {
        case totalTasks = "total_tasks"
        case totalRuns = "total_runs"
        case successRuns = "success_runs"
        case failedRuns = "failed_runs"
        case recentLogs = "recent_logs"
    }
}

struct UpdateData: Codable {
    let hasUpdate: Bool?
    let latestVersion: String?
    let currentVersion: String?
    let changelog: String?

    enum CodingKeys: String, CodingKey {
        case hasUpdate = "has_update"
        case latestVersion = "latest_version"
        case currentVersion = "current_version"
        case changelog
    }
}

struct BackupData: Codable {
    let name: String
    let size: Int64?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, size
        case createdAt = "created_at"
    }
}

struct RestoreProgressData: Codable {
    let status: String?
    let progress: Double?
    let message: String?
}

struct TaskLogFileData: Codable {
    let name: String
    let size: Int64?
    let modifiedAt: Date?

    enum CodingKeys: String, CodingKey {
        case name, size
        case modifiedAt = "modified_at"
    }
}

struct TaskStatsData: Codable {
    let total: Int?
    let enabled: Int?
    let disabled: Int?
    let running: Int?

    enum CodingKeys: String, CodingKey {
        case total, enabled, disabled, running
    }
}

struct CronParseData: Codable {
    let nextRuns: [String]?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case nextRuns = "next_runs"
        case description
    }
}

struct CronTemplateData: Codable {
    let name: String
    let expression: String
    let description: String?
}

struct ScriptNodeData: Codable {
    let name: String
    let path: String
    let isDir: Bool
    let children: [ScriptNodeData]?

    enum CodingKeys: String, CodingKey {
        case name, path, isDir = "is_dir", children
    }
}

struct ScriptContentData: Codable {
    let content: String
    let language: String?
    let size: Int64?
}

struct ScriptRunData: Codable {
    let id: String?
    let pid: Int?
}

struct ScriptRunLogData: Codable {
    let id: String
    let path: String?
    let status: String?
    let output: String?
    let startedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, path, status, output
        case startedAt = "started_at"
    }
}

struct ScriptFormatData: Codable {
    let formatted: String
}

struct NotifyTypeData: Codable {
    let type: String
    let name: String
    let fields: [NotifyFieldData]?
}

struct NotifyFieldData: Codable {
    let key: String
    let label: String
    let type: String
    let required: Bool?
    let placeholder: String?
}

struct MirrorData: Codable {
    let name: String
    let url: String
    let type: String?
}

struct PythonRuntimeData: Codable {
    let version: String
    let path: String?
    let isDefault: Bool?

    enum CodingKeys: String, CodingKey {
        case version, path
        case isDefault = "is_default"
    }
}

struct TwoFaSetupData: Codable {
    let secret: String?
    let qrCodeUrl: String?
    let otpauthUrl: String?

    enum CodingKeys: String, CodingKey {
        case secret
        case qrCodeUrl = "qr_code_url"
        case otpauthUrl = "otpauth_url"
    }
}

struct TwoFaStatusData: Codable {
    let enabled: Bool
}

struct OpenApiAppData: Codable, Identifiable {
    let id: Int
    let name: String
    let enabled: Bool
    let secret: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, enabled, secret
        case createdAt = "created_at"
    }
}

struct OpenApiSecretData: Codable {
    let secret: String
}

private struct RefreshTokenBody: Codable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}
