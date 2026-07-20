import Foundation

struct NotifyChannel: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let type: String
    let config: [String: AnyCodable]
    let enabled: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, type, config, enabled
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        name = try c.decodeString(forKey: .name)
        type = try c.decodeString(forKey: .type)
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        createdAt = try c.decodeDate(forKey: .createdAt)
        updatedAt = try c.decodeDate(forKey: .updatedAt)

        if let dict = try? c.decode([String: AnyCodable].self, forKey: .config) {
            config = dict
        } else if let str = try? c.decode(String.self, forKey: .config),
                  let data = str.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
            config = dict
        } else {
            config = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(type, forKey: .type)
        try c.encode(config, forKey: .config)
    }

    static func == (lhs: NotifyChannel, rhs: NotifyChannel) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.type == rhs.type
            && lhs.enabled == rhs.enabled
    }
}

struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Bool.self) { value = v }
        else if let v = try? c.decode(Int.self) { value = v }
        else if let v = try? c.decode(Double.self) { value = v }
        else if let v = try? c.decode(String.self) { value = v }
        else if let v = try? c.decode([AnyCodable].self) { value = v }
        else if let v = try? c.decode([String: AnyCodable].self) { value = v }
        else { value = "" }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if let v = value as? Bool { try c.encode(v) }
        else if let v = value as? Int { try c.encode(v) }
        else if let v = value as? Double { try c.encode(v) }
        else if let v = value as? String { try c.encode(v) }
        else if let v = value as? [AnyCodable] { try c.encode(v) }
        else if let v = value as? [String: AnyCodable] { try c.encode(v) }
        else { try c.encodeNil() }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Bool, r as Bool): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as String, r as String): return l == r
        default: return false
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

    func decodeDate(forKey key: Key) throws -> Date {
        guard let s = try? decode(String.self, forKey: key) else { return Date() }
        return DateParser.parse(s) ?? Date()
    }
}
