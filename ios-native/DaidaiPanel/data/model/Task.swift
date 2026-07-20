import Foundation

struct TaskItem: Codable, Identifiable, Equatable {
    static let groupLabelPrefix = "分组:"

    let id: Int
    let name: String
    let command: String
    let cronExpression: String
    let cronExpressions: [String]
    let taskType: String
    let pythonVersion: String
    let status: Double
    let labels: String
    let displayLabels: [String]
    let lastRunAt: Date?
    let nextRunAt: Date?
    let lastRunStatus: Int?
    let timeout: Int
    let randomDelaySeconds: Int?
    let maxRetries: Int
    let retryInterval: Int
    let notifyOnFailure: Bool
    let notifyOnSuccess: Bool
    let notificationChannelId: Int?
    let dependsOn: Int?
    let sortOrder: Int
    let isPinned: Bool
    let taskBefore: String?
    let taskAfter: String?
    let allowMultipleInstances: Bool
    let notificationChannelName: String?
    let notificationChannelEnabled: Bool?
    let lastRunningTime: Double?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, command, status, labels, timeout
        case cronExpression = "cron_expression"
        case cronExpressions = "cron_expressions"
        case taskType = "task_type"
        case pythonVersion = "python_version"
        case displayLabels = "display_labels"
        case lastRunAt = "last_run_at"
        case nextRunAt = "next_run_at"
        case lastRunStatus = "last_run_status"
        case randomDelaySeconds = "random_delay_seconds"
        case maxRetries = "max_retries"
        case retryInterval = "retry_interval"
        case notifyOnFailure = "notify_on_failure"
        case notifyOnSuccess = "notify_on_success"
        case notificationChannelId = "notification_channel_id"
        case dependsOn = "depends_on"
        case sortOrder = "sort_order"
        case isPinned = "is_pinned"
        case taskBefore = "task_before"
        case taskAfter = "task_after"
        case allowMultipleInstances = "allow_multiple_instances"
        case notificationChannelName = "notification_channel_name"
        case notificationChannelEnabled = "notification_channel_enabled"
        case lastRunningTime = "last_running_time"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        name = try c.decodeString(forKey: .name)
        command = try c.decodeString(forKey: .command)
        cronExpression = try c.decodeString(forKey: .cronExpression)
        cronExpressions = (try? c.decode([String].self, forKey: .cronExpressions)) ?? []
        taskType = try c.decodeStringDefault(forKey: .taskType, defaultValue: "cron")
        pythonVersion = try c.decodeStringDefault(forKey: .pythonVersion, defaultValue: "3.12")
        status = try c.decodeDouble(forKey: .status)
        labels = try c.decodeString(forKey: .labels)
        displayLabels = (try? c.decode([String].self, forKey: .displayLabels)) ?? []
        lastRunAt = try c.decodeDateIfPresent(forKey: .lastRunAt)
        nextRunAt = try c.decodeDateIfPresent(forKey: .nextRunAt)
        lastRunStatus = try c.decodeIntIfPresent(forKey: .lastRunStatus)
        timeout = try c.decodeInt(forKey: .timeout)
        randomDelaySeconds = try c.decodeIntIfPresent(forKey: .randomDelaySeconds)
        maxRetries = try c.decodeInt(forKey: .maxRetries)
        retryInterval = try c.decodeInt(forKey: .retryInterval)
        notifyOnFailure = (try? c.decode(Bool.self, forKey: .notifyOnFailure)) ?? false
        notifyOnSuccess = (try? c.decode(Bool.self, forKey: .notifyOnSuccess)) ?? false
        notificationChannelId = try c.decodeIntIfPresent(forKey: .notificationChannelId)
        dependsOn = try c.decodeIntIfPresent(forKey: .dependsOn)
        sortOrder = try c.decodeInt(forKey: .sortOrder)
        isPinned = (try? c.decode(Bool.self, forKey: .isPinned)) ?? false
        taskBefore = try c.decodeStringIfPresent(forKey: .taskBefore)
        taskAfter = try c.decodeStringIfPresent(forKey: .taskAfter)
        allowMultipleInstances = (try? c.decode(Bool.self, forKey: .allowMultipleInstances)) ?? false
        notificationChannelName = try c.decodeStringIfPresent(forKey: .notificationChannelName)
        notificationChannelEnabled = try c.decode(Bool?.self, forKey: .notificationChannelEnabled)
        lastRunningTime = try c.decodeDoubleIfPresent(forKey: .lastRunningTime)
        createdAt = try c.decodeDate(forKey: .createdAt)
        updatedAt = try c.decodeDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(command, forKey: .command)
        try c.encode(cronExpression, forKey: .cronExpression)
        try c.encode(taskType, forKey: .taskType)
        try c.encode(pythonVersion, forKey: .pythonVersion)
        try c.encode(labels, forKey: .labels)
        try c.encode(timeout, forKey: .timeout)
        try c.encodeIfPresent(randomDelaySeconds, forKey: .randomDelaySeconds)
        try c.encode(maxRetries, forKey: .maxRetries)
        try c.encode(retryInterval, forKey: .retryInterval)
        try c.encode(notifyOnFailure, forKey: .notifyOnFailure)
        try c.encode(notifyOnSuccess, forKey: .notifyOnSuccess)
        try c.encodeIfPresent(notificationChannelId, forKey: .notificationChannelId)
        try c.encodeIfPresent(dependsOn, forKey: .dependsOn)
        try c.encode(sortOrder, forKey: .sortOrder)
        try c.encodeIfPresent(taskBefore, forKey: .taskBefore)
        try c.encodeIfPresent(taskAfter, forKey: .taskAfter)
        try c.encode(allowMultipleInstances, forKey: .allowMultipleInstances)
    }

    var isDisabled: Bool { status == 0 }
    var isQueued: Bool { status == 0.5 }
    var isEnabled: Bool { status == 1 }
    var isRunning: Bool { status == 2 }

    var statusText: String {
        if isRunning { return "运行中" }
        if isQueued { return "排队中" }
        if isEnabled { return "已启用" }
        return "已禁用"
    }

    var labelList: [String] {
        guard !labels.isEmpty else { return [] }
        return labels.split(separator: ",").map { String($0) }.filter { !$0.isEmpty }
    }

    var labelsForDisplay: [String] {
        displayLabels.isEmpty ? labelList : displayLabels
    }

    static func isGroupLabel(_ label: String) -> Bool {
        label.trimmingCharacters(in: .whitespaces).hasPrefix(Self.groupLabelPrefix)
    }

    static func toGroupLabel(_ group: String) -> String {
        "\(Self.groupLabelPrefix)\(group.trimmingCharacters(in: .whitespaces))"
    }

    var groupName: String? {
        for label in labelList {
            let trimmed = label.trimmingCharacters(in: .whitespaces)
            if Self.isGroupLabel(trimmed) {
                let group = trimmed.dropFirst(Self.groupLabelPrefix.count).trimmingCharacters(in: .whitespaces)
                if !group.isEmpty { return String(group) }
            }
        }
        return nil
    }

    var userLabelsForDisplay: [String] {
        var visible = labelsForDisplay.filter { !Self.isGroupLabel($0) }
        if let group = groupName, !group.isEmpty {
            visible.removeAll { $0 == group }
        }
        return visible
    }
}

private extension KeyedDecodingContainer {
    func decodeInt(forKey key: Key) throws -> Int {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
        if let s = try? decode(String.self, forKey: key), let v = Int(s) { return v }
        return 0
    }

    func decodeIntIfPresent(forKey key: Key) throws -> Int? {
        if let v = try decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try decodeIfPresent(Double.self, forKey: key) { return Int(v) }
        if let s = try decodeIfPresent(String.self, forKey: key), let v = Int(s) { return v }
        return nil
    }

    func decodeDouble(forKey key: Key) throws -> Double {
        if let v = try? decode(Double.self, forKey: key) { return v }
        if let v = try? decode(Int.self, forKey: key) { return Double(v) }
        if let s = try? decode(String.self, forKey: key), let v = Double(s) { return v }
        return 0
    }

    func decodeDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let v = try decodeIfPresent(Double.self, forKey: key) { return v }
        if let v = try decodeIfPresent(Int.self, forKey: key) { return Double(v) }
        return nil
    }

    func decodeString(forKey key: Key) throws -> String {
        (try? decode(String.self, forKey: key)) ?? ""
    }

    func decodeStringDefault(forKey key: Key, defaultValue: String) throws -> String {
        (try? decode(String.self, forKey: key)) ?? defaultValue
    }

    func decodeStringIfPresent(forKey key: Key) throws -> String? {
        try? decode(String?.self, forKey: key)
    }

    func decodeDate(forKey key: Key) throws -> Date {
        let s = try decode(String.self, forKey: key)
        return DateParser.parse(s) ?? Date()
    }

    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        guard let s = try decode(String?.self, forKey: key) else { return nil }
        return DateParser.parse(s)
    }
}

enum DateParser {
    private static let iso8601Full: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let fallback: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let fallbackNoMs: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func parse(_ string: String) -> Date? {
        if let d = iso8601Full.date(from: string) { return d }
        if let d = iso8601.date(from: string) { return d }
        if let d = fallback.date(from: string) { return d }
        if let d = fallbackNoMs.date(from: string) { return d }
        return nil
    }
}
