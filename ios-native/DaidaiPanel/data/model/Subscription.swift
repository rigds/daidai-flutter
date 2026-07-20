import Foundation

struct Subscription: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let type: String
    let url: String
    let branch: String
    let subPath: String?
    let schedule: String
    let whitelist: String
    let blacklist: String
    let autoAddTask: Bool
    let autoDelTask: Bool
    let enabled: Bool
    let status: Double
    let lastPullAt: Date?
    let saveDir: String
    let sshKeyId: Int?
    let alias: String
    let dependOn: String
    let hookScript: String
    let forceOverwrite: Bool?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, type, url, branch, schedule, whitelist, blacklist, enabled, status, alias
        case subPath = "sub_path"
        case autoAddTask = "auto_add_task"
        case autoDelTask = "auto_del_task"
        case lastPullAt = "last_pull_at"
        case saveDir = "save_dir"
        case sshKeyId = "ssh_key_id"
        case dependOn = "depend_on"
        case hookScript = "hook_script"
        case forceOverwrite = "force_overwrite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        name = try c.decodeString(forKey: .name)
        type = try c.decodeStringDefault(forKey: .type, defaultValue: "public-repo")
        url = try c.decodeString(forKey: .url)
        branch = try c.decodeString(forKey: .branch)
        subPath = try? c.decodeStringIfPresent(forKey: .subPath)
        schedule = try c.decodeString(forKey: .schedule)
        whitelist = try c.decodeString(forKey: .whitelist)
        blacklist = try c.decodeString(forKey: .blacklist)
        autoAddTask = (try? c.decode(Bool.self, forKey: .autoAddTask)) ?? false
        autoDelTask = (try? c.decode(Bool.self, forKey: .autoDelTask)) ?? false
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        status = try c.decodeDouble(forKey: .status)
        lastPullAt = try? c.decodeDateIfPresent(forKey: .lastPullAt)
        saveDir = try c.decodeString(forKey: .saveDir)
        sshKeyId = try? c.decodeIntIfPresent(forKey: .sshKeyId)
        alias = try c.decodeString(forKey: .alias)
        dependOn = try c.decodeString(forKey: .dependOn)
        hookScript = try c.decodeString(forKey: .hookScript)
        forceOverwrite = try? c.decode(Bool?.self, forKey: .forceOverwrite)
        createdAt = try c.decodeDate(forKey: .createdAt)
        updatedAt = try c.decodeDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(normalizedType, forKey: .type)
        try c.encode(url, forKey: .url)
        try c.encode(branch, forKey: .branch)
        try c.encodeIfPresent(subPath, forKey: .subPath)
        try c.encode(schedule, forKey: .schedule)
        try c.encode(whitelist, forKey: .whitelist)
        try c.encode(blacklist, forKey: .blacklist)
        try c.encode(autoAddTask, forKey: .autoAddTask)
        try c.encode(autoDelTask, forKey: .autoDelTask)
        try c.encode(saveDir, forKey: .saveDir)
        try c.encodeIfPresent(sshKeyId, forKey: .sshKeyId)
        try c.encode(alias, forKey: .alias)
        try c.encode(dependOn, forKey: .dependOn)
        try c.encode(hookScript, forKey: .hookScript)
        try c.encode(forceOverwrite ?? true, forKey: .forceOverwrite)
    }

    var isRunning: Bool { status == 2 }
    var isPulling: Bool { status == 2 }

    var normalizedType: String {
        switch type {
        case "file": return "single-file"
        case "public-repo", "private-repo": return "git-repo"
        case "": return "git-repo"
        default: return type
        }
    }

    var isSingleFile: Bool { normalizedType == "single-file" }
    var isGitRepo: Bool { normalizedType == "git-repo" }

    var typeLabel: String {
        if isSingleFile { return "单文件" }
        if isGitRepo { return "Git 仓库" }
        return normalizedType
    }

    var statusText: String {
        if isRunning { return "拉取中" }
        if enabled { return "已启用" }
        return "已禁用"
    }
}

private extension KeyedDecodingContainer {
    func decodeInt(forKey key: Key) throws -> Int {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
        return 0
    }

    func decodeIntIfPresent(forKey key: Key) throws -> Int? {
        if let v = try? decode(Int?.self, forKey: key) { return v }
        if let v = try? decode(Double?.self, forKey: key) { return v.map { Int($0) } }
        return nil
    }

    func decodeDouble(forKey key: Key) throws -> Double {
        if let v = try? decode(Double.self, forKey: key) { return v }
        if let v = try? decode(Int.self, forKey: key) { return Double(v) }
        return 0
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
        guard let s = try? decode(String.self, forKey: key) else { return Date() }
        return DateParser.parse(s) ?? Date()
    }

    func decodeDateIfPresent(forKey key: Key) throws -> Date? {
        guard let s = try decode(String?.self, forKey: key) else { return nil }
        return DateParser.parse(s)
    }
}
