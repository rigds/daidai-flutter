import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let username: String
    let role: String
    let enabled: Bool
    let avatarUrl: String?
    let lastLoginAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, username, role, enabled
        case avatarUrl = "avatar_url"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        role = (try? c.decode(String.self, forKey: .role)) ?? "viewer"
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        let rawAvatar = try? c.decode(String?.self, forKey: .avatarUrl)
        avatarUrl = (rawAvatar.flatMap { $0.isEmpty ? nil : $0 })
        lastLoginAt = try? c.decodeDateIfPresent(forKey: .lastLoginAt)
        createdAt = try c.decodeDate(forKey: .createdAt)
        updatedAt = try c.decodeDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(username, forKey: .username)
        try c.encode(role, forKey: .role)
        try c.encode(enabled, forKey: .enabled)
        try c.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
    }

    var isAdmin: Bool { role == "admin" }
    var isOperator: Bool { role == "operator" || isAdmin }
    var isViewer: Bool { true }

    func hasMinRole(_ minRole: String) -> Bool {
        let hierarchy: [String: Int] = ["viewer": 0, "operator": 1, "admin": 2]
        return (hierarchy[role] ?? 0) >= (hierarchy[minRole] ?? 0)
    }
}

private extension KeyedDecodingContainer {
    func decodeInt(forKey key: Key) throws -> Int {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
        return 0
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
