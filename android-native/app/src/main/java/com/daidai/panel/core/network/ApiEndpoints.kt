package com.daidai.panel.core.network

object ApiEndpoints {
    // Auth
    const val AUTH_CHECK_INIT = "/api/auth/check-init"
    const val AUTH_INIT = "/api/auth/init"
    const val AUTH_LOGIN = "/api/auth/login"
    const val AUTH_LOGOUT = "/api/auth/logout"
    const val AUTH_REFRESH = "/api/auth/refresh"
    const val AUTH_USER = "/api/auth/user"
    const val AUTH_PASSWORD = "/api/auth/password"
    const val AUTH_CAPTCHA_CONFIG = "/api/auth/captcha-config"

    // System
    const val SYSTEM_HEALTH = "/api/system/health"
    const val SYSTEM_VERSION = "/api/system/version"
    const val SYSTEM_INFO = "/api/system/info"
    const val SYSTEM_DASHBOARD = "/api/system/dashboard"
    const val SYSTEM_STATS = "/api/system/stats"
    const val SYSTEM_CHECK_UPDATE = "/api/system/check-update"
    const val SYSTEM_SETTINGS = "/api/system/settings"
    const val SYSTEM_LOG = "/api/system/log"
    const val SYSTEM_SPONSORS = "/api/system/sponsors"
    const val SYSTEM_BACKUP = "/api/system/backup"
    const val SYSTEM_BACKUPS = "/api/system/backups"
    const val SYSTEM_BACKUP_UPLOAD = "/api/system/backup/upload"
    const val SYSTEM_BACKUP_DOWNLOAD = "/api/system/backup/download"
    const val SYSTEM_RESTORE = "/api/system/restore"
    const val SYSTEM_RESTORE_PROGRESS = "/api/system/restore/progress"

    // Tasks
    const val TASKS = "/api/tasks"
    const val TASKS_RUN = "/api/tasks/run"
    const val TASKS_STOP = "/api/tasks/stop"
    const val TASKS_ENABLE = "/api/tasks/enable"
    const val TASKS_DISABLE = "/api/tasks/disable"
    const val TASKS_PIN = "/api/tasks/pin"
    const val TASKS_UNPIN = "/api/tasks/unpin"
    const val TASKS_COPY = "/api/tasks/copy"
    const val TASKS_LATEST_LOG = "/api/tasks/latest-log"
    const val TASKS_LIVE_LOGS = "/api/tasks/live-logs"
    const val TASKS_LOG_FILES = "/api/tasks/log-files"
    const val TASKS_STATS = "/api/tasks/stats"
    const val TASKS_BATCH = "/api/tasks/batch"
    const val TASKS_CLEAN_LOGS = "/api/tasks/clean-logs"
    const val TASKS_EXPORT = "/api/tasks/export"
    const val TASKS_IMPORT = "/api/tasks/import"
    const val TASKS_CRON_PARSE = "/api/tasks/cron-parse"
    const val TASKS_CRON_TEMPLATES = "/api/tasks/cron-templates"
    const val TASKS_NOTIFICATION_CHANNELS = "/api/tasks/notification-channels"

    // Logs
    const val LOGS = "/api/logs"
    const val LOGS_STREAM = "/api/logs/stream"
    const val LOGS_BATCH_DELETE = "/api/logs/batch-delete"
    const val LOGS_CLEAN = "/api/logs/clean"

    // Scripts
    const val SCRIPTS_TREE = "/api/scripts/tree"
    const val SCRIPTS_CONTENT = "/api/scripts/content"
    const val SCRIPTS_DOWNLOAD = "/api/scripts/download"
    const val SCRIPTS_UPLOAD = "/api/scripts/upload"
    const val SCRIPTS_DIRECTORY = "/api/scripts/directory"
    const val SCRIPTS_RENAME = "/api/scripts/rename"
    const val SCRIPTS_MOVE = "/api/scripts/move"
    const val SCRIPTS_COPY = "/api/scripts/copy"
    const val SCRIPTS_BATCH = "/api/scripts/batch"
    const val SCRIPTS_VERSIONS = "/api/scripts/versions"
    const val SCRIPTS_RUN = "/api/scripts/run"
    const val SCRIPTS_RUN_CODE = "/api/scripts/run-code"
    const val SCRIPTS_RUN_LOGS = "/api/scripts/run-logs"
    const val SCRIPTS_RUN_STOP = "/api/scripts/run-stop"
    const val SCRIPTS_RUN_CLEAR = "/api/scripts/run-clear"
    const val SCRIPTS_FORMAT = "/api/scripts/format"

    // EnvVars
    const val ENVS = "/api/envs"
    const val ENVS_ENABLE = "/api/envs/enable"
    const val ENVS_DISABLE = "/api/envs/disable"
    const val ENVS_MOVE_TOP = "/api/envs/move-top"
    const val ENVS_CANCEL_TOP = "/api/envs/cancel-top"
    const val ENVS_BATCH = "/api/envs/batch"
    const val ENVS_GROUPS = "/api/envs/groups"
    const val ENVS_EXPORT = "/api/envs/export"
    const val ENVS_IMPORT = "/api/envs/import"

    // Subscriptions
    const val SUBSCRIPTIONS = "/api/subscriptions"
    const val SUBSCRIPTIONS_ENABLE = "/api/subscriptions/enable"
    const val SUBSCRIPTIONS_DISABLE = "/api/subscriptions/disable"
    const val SUBSCRIPTIONS_PULL = "/api/subscriptions/pull"
    const val SUBSCRIPTIONS_PULL_STOP = "/api/subscriptions/pull-stop"
    const val SUBSCRIPTIONS_PULL_STREAM = "/api/subscriptions/pull-stream"
    const val SUBSCRIPTIONS_LOGS = "/api/subscriptions/logs"
    const val SUBSCRIPTIONS_BATCH_DELETE = "/api/subscriptions/batch-delete"

    // Notifications
    const val NOTIFICATIONS = "/api/notifications"
    const val NOTIFICATIONS_ENABLE = "/api/notifications/enable"
    const val NOTIFICATIONS_DISABLE = "/api/notifications/disable"
    const val NOTIFICATIONS_TEST = "/api/notifications/test"
    const val NOTIFICATIONS_TYPES = "/api/notifications/types"
    const val NOTIFICATIONS_SEND = "/api/notifications/send"

    // Dependencies
    const val DEPS = "/api/deps"
    const val DEPS_STATUS = "/api/deps/status"
    const val DEPS_REINSTALL = "/api/deps/reinstall"
    const val DEPS_CANCEL = "/api/deps/cancel"
    const val DEPS_LOG_STREAM = "/api/deps/log-stream"
    const val DEPS_BATCH_DELETE = "/api/deps/batch-delete"
    const val DEPS_PIP = "/api/deps/pip"
    const val DEPS_NPM = "/api/deps/npm"
    const val DEPS_MIRRORS = "/api/deps/mirrors"
    const val DEPS_PYTHON_RUNTIMES = "/api/deps/python-runtimes"
    const val DEPS_PYTHON_RUNTIME_DEFAULT = "/api/deps/python-runtime-default"

    // Users
    const val USERS = "/api/users"
    const val USERS_RESET_PASSWORD = "/api/users/reset-password"

    // Security
    const val SECURITY = "/api/security"
    const val SECURITY_LOGIN_LOGS = "/api/security/login-logs"
    const val SECURITY_SESSIONS = "/api/security/sessions"
    const val SECURITY_SESSIONS_OTHERS = "/api/security/sessions/others"
    const val SECURITY_SESSION_BY_ID = "/api/security/sessions/by-id"
    const val SECURITY_IP_WHITELIST = "/api/security/ip-whitelist"
    const val SECURITY_IP_WHITELIST_BY_ID = "/api/security/ip-whitelist/by-id"
    const val SECURITY_AUDIT_LOGS = "/api/security/audit-logs"
    const val SECURITY_LOGIN_STATS = "/api/security/login-stats"
    const val SECURITY_2FA_SETUP = "/api/security/2fa/setup"
    const val SECURITY_2FA_VERIFY = "/api/security/2fa/verify"
    const val SECURITY_2FA = "/api/security/2fa"
    const val SECURITY_2FA_STATUS = "/api/security/2fa/status"

    // Configs
    const val CONFIGS = "/api/configs"
    const val CONFIGS_BATCH = "/api/configs/batch"

    // SSH Keys
    const val SSH_KEYS = "/api/ssh-keys"

    // OpenAPI
    const val OPENAPI = "/api/openapi"
    const val OPENAPI_TOKEN = "/api/openapi/token"
    const val OPENAPI_APPS = "/api/openapi/apps"
    const val OPENAPI_APPS_ENABLE = "/api/openapi/apps/enable"
    const val OPENAPI_APPS_DISABLE = "/api/openapi/apps/disable"
    const val OPENAPI_APPS_RESET_SECRET = "/api/openapi/apps/reset-secret"
    const val OPENAPI_APPS_VIEW_SECRET = "/api/openapi/apps/view-secret"
    const val OPENAPI_APPS_LOGS = "/api/openapi/apps/logs"
}
