import Foundation

struct Dependency: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let version: String
    let type: String
    let pythonVersion: String
    let status: String
    let remark: String?
    let log: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, version, type, status, remark, log
        case pythonVersion = "python_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        name = try c.decodeString(forKey: .name)
        version = try c.decodeString(forKey: .version)
        type = try c.decodeStringDefault(forKey: .type, defaultValue: "nodejs")
        pythonVersion = try c.decodeString(forKey: .pythonVersion)
        status = try c.decodeStringDefault(forKey: .status, defaultValue: "installed")
        remark = try? c.decodeStringIfPresent(forKey: .remark)
        log = try? c.decodeStringIfPresent(forKey: .log)
        createdAt = try c.decodeDate(forKey: .createdAt)
        updatedAt = try c.decodeDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(version, forKey: .version)
        try c.encode(type, forKey: .type)
        try c.encode(pythonVersion, forKey: .pythonVersion)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(remark, forKey: .remark)
        try c.encodeIfPresent(log, forKey: .log)
    }

    var isQueued: Bool { status == "queued" }
    var isInstalling: Bool { status == "installing" }
    var isRemoving: Bool { status == "removing" }
    var isInstalled: Bool { status == "installed" }
    var isFailed: Bool { status == "failed" }
    var isCancelled: Bool { status == "cancelled" }
    var isBusy: Bool { isInstalling || isRemoving || isQueued }

    var statusText: String {
        switch status {
        case "queued": return "排队中"
        case "installing": return "安装中"
        case "removing": return "卸载中"
        case "failed": return "失败"
        case "cancelled": return "已取消"
        default: return "已安装"
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeInt(forKey key: Key) throws -> Int {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
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
}
