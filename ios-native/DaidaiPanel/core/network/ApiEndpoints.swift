import Foundation

struct ApiEndpoints {
    private var baseURL: String

    init(baseURL: String) {
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
    }

    mutating func updateBaseURL(_ url: String) {
        self.baseURL = url.hasSuffix("/") ? String(url.dropLast()) : url
    }

    private func path(_ p: String) -> String { "\(baseURL)/api\(p)" }

    // MARK: - Auth
    var checkInit: String { path("/auth/init") }
    var initAdmin: String { path("/auth/init") }
    var login: String { path("/auth/login") }
    var logout: String { path("/auth/logout") }
    var refreshToken: String { path("/auth/refresh") }
    var getUser: String { path("/auth/user") }
    var changePassword: String { path("/auth/password") }
    var captchaConfig: String { path("/auth/captcha/config") }

    // MARK: - System
    var health: String { path("/system/health") }
    var version: String { path("/system/version") }
    var systemInfo: String { path("/system/info") }
    var dashboard: String { path("/system/dashboard") }
    var systemStats: String { path("/system/stats") }
    var systemVersion: String { path("/system/version") }
    var checkUpdate: String { path("/system/update/check") }
    var panelSettings: String { path("/system/settings") }
    var panelLog: String { path("/system/log") }
    var sponsors: String { path("/system/sponsors") }
    var backup: String { path("/system/backup") }
    var backups: String { path("/system/backups") }
    var backupUpload: String { path("/system/backup/upload") }
    func backupDownload(_ name: String) -> String { path("/system/backup/download/\(name)") }
    var restore: String { path("/system/restore") }
    var restoreProgress: String { path("/system/restore/progress") }

    // MARK: - Tasks
    var tasks: String { path("/tasks") }
    func task(_ id: Int) -> String { path("/tasks/\(id)") }
    func taskRun(_ id: Int) -> String { path("/tasks/\(id)/run") }
    func taskStop(_ id: Int) -> String { path("/tasks/\(id)/stop") }
    func taskEnable(_ id: Int) -> String { path("/tasks/\(id)/enable") }
    func taskDisable(_ id: Int) -> String { path("/tasks/\(id)/disable") }
    func taskPin(_ id: Int) -> String { path("/tasks/\(id)/pin") }
    func taskUnpin(_ id: Int) -> String { path("/tasks/\(id)/unpin") }
    func taskCopy(_ id: Int) -> String { path("/tasks/\(id)/copy") }
    func taskLatestLog(_ id: Int) -> String { path("/tasks/\(id)/logs/latest") }
    func taskLiveLogs(_ id: Int) -> String { path("/tasks/\(id)/logs/live") }
    func taskLogFiles(_ id: Int) -> String { path("/tasks/\(id)/logs/files") }
    var taskStats: String { path("/tasks/stats") }
    var taskBatchEnable: String { path("/tasks/batch/enable") }
    var taskBatchDisable: String { path("/tasks/batch/disable") }
    var taskBatchRun: String { path("/tasks/batch/run") }
    var taskBatchDelete: String { path("/tasks/batch/delete") }
    var taskCleanLogs: String { path("/tasks/logs/clean") }
    var taskExport: String { path("/tasks/export") }
    var taskImport: String { path("/tasks/import") }
    var cronParse: String { path("/tasks/cron/parse") }
    var cronTemplates: String { path("/tasks/cron/templates") }
    var taskNotificationChannels: String { path("/tasks/notification-channels") }

    // MARK: - Logs
    var logs: String { path("/logs") }
    func log(_ id: Int) -> String { path("/logs/\(id)") }
    var logStream: String { path("/logs/stream") }
    var logBatchDelete: String { path("/logs/batch") }
    var logClean: String { path("/logs/clean") }

    // MARK: - Scripts
    var scriptTree: String { path("/scripts/tree") }
    var scriptContent: String { path("/scripts/content") }
    var scriptDownload: String { path("/scripts/download") }
    var scriptUpload: String { path("/scripts/upload") }
    var scriptDirectory: String { path("/scripts/directory") }
    var scriptRename: String { path("/scripts/rename") }
    var scriptMove: String { path("/scripts/move") }
    var scriptCopy: String { path("/scripts/copy") }
    var scriptBatch: String { path("/scripts/batch") }
    var scriptVersions: String { path("/scripts/versions") }
    var scriptRun: String { path("/scripts/run") }
    var scriptRunCode: String { path("/scripts/run-code") }
    var scriptRunLogs: String { path("/scripts/run/logs") }
    var scriptRunStop: String { path("/scripts/run/stop") }
    var scriptRunClear: String { path("/scripts/run/clear") }
    var scriptFormat: String { path("/scripts/format") }

    // MARK: - Envs
    var envs: String { path("/envs") }
    func env(_ id: Int) -> String { path("/envs/\(id)") }
    func envEnable(_ id: Int) -> String { path("/envs/\(id)/enable") }
    func envDisable(_ id: Int) -> String { path("/envs/\(id)/disable") }
    func envMoveTop(_ id: Int) -> String { path("/envs/\(id)/move-top") }
    func envCancelTop(_ id: Int) -> String { path("/envs/\(id)/cancel-top") }
    var envBatchEnable: String { path("/envs/batch/enable") }
    var envBatchDisable: String { path("/envs/batch/disable") }
    var envBatchDelete: String { path("/envs/batch/delete") }
    var envGroups: String { path("/envs/groups") }
    var envExport: String { path("/envs/export") }
    var envImport: String { path("/envs/import") }

    // MARK: - Subscriptions
    var subscriptions: String { path("/subscriptions") }
    func subscription(_ id: Int) -> String { path("/subscriptions/\(id)") }
    func subscriptionEnable(_ id: Int) -> String { path("/subscriptions/\(id)/enable") }
    func subscriptionDisable(_ id: Int) -> String { path("/subscriptions/\(id)/disable") }
    func subscriptionPull(_ id: Int) -> String { path("/subscriptions/\(id)/pull") }
    func subscriptionPullStop(_ id: Int) -> String { path("/subscriptions/\(id)/pull/stop") }
    func subscriptionPullStream(_ id: Int) -> String { path("/subscriptions/\(id)/pull/stream") }
    func subscriptionLogs(_ id: Int) -> String { path("/subscriptions/\(id)/logs") }
    var subscriptionBatchDelete: String { path("/subscriptions/batch") }

    // MARK: - Notifications
    var notifications: String { path("/notifications") }
    func notification(_ id: Int) -> String { path("/notifications/\(id)") }
    func notificationEnable(_ id: Int) -> String { path("/notifications/\(id)/enable") }
    func notificationDisable(_ id: Int) -> String { path("/notifications/\(id)/disable") }
    func notificationTest(_ id: Int) -> String { path("/notifications/\(id)/test") }
    var notificationTypes: String { path("/notifications/types") }
    var notificationSend: String { path("/notifications/send") }

    // MARK: - Dependencies
    var deps: String { path("/deps") }
    func dep(_ id: Int) -> String { path("/deps/\(id)") }
    func depStatus(_ id: Int) -> String { path("/deps/\(id)/status") }
    func depReinstall(_ id: Int) -> String { path("/deps/\(id)/reinstall") }
    func depCancel(_ id: Int) -> String { path("/deps/\(id)/cancel") }
    func depLogStream(_ id: Int) -> String { path("/deps/\(id)/log/stream") }
    var depBatchDelete: String { path("/deps/batch") }
    var depPip: String { path("/deps/pip") }
    var depNpm: String { path("/deps/npm") }
    var depMirrors: String { path("/deps/mirrors") }
    var depPythonRuntimes: String { path("/deps/python/runtimes") }
    var depPythonRuntimeDefault: String { path("/deps/python/runtimes/default") }

    // MARK: - Users
    var users: String { path("/users") }
    func user(_ id: Int) -> String { path("/users/\(id)") }
    func userResetPassword(_ id: Int) -> String { path("/users/\(id)/password") }

    // MARK: - Security
    var loginLogs: String { path("/security/login-logs") }
    var sessions: String { path("/security/sessions") }
    var ipWhitelist: String { path("/security/ip-whitelist") }
    var auditLogs: String { path("/security/audit-logs") }
    var loginStats: String { path("/security/login-stats") }
    var twoFaSetup: String { path("/security/2fa/setup") }
    var twoFaVerify: String { path("/security/2fa/verify") }
    var twoFaStatus: String { path("/security/2fa/status") }

    // MARK: - Configs
    var configs: String { path("/configs") }
    func config(_ key: String) -> String { path("/configs/\(key)") }
    var configBatch: String { path("/configs/batch") }

    // MARK: - OpenAPI Apps
    var openApiApps: String { path("/openapi/apps") }
    func openApiApp(_ id: Int) -> String { path("/openapi/apps/\(id)") }
    func openApiAppEnable(_ id: Int) -> String { path("/openapi/apps/\(id)/enable") }
    func openApiAppDisable(_ id: Int) -> String { path("/openapi/apps/\(id)/disable") }
    func openApiAppResetSecret(_ id: Int) -> String { path("/openapi/apps/\(id)/secret/reset") }
    func openApiAppViewSecret(_ id: Int) -> String { path("/openapi/apps/\(id)/secret") }
    func openApiAppLogs(_ id: Int) -> String { path("/openapi/apps/\(id)/logs") }
}
