import Foundation

struct EnvVar: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let value: String
    let remarks: String
    let enabled: Bool
    let position: Double
    let sortOrder: Int
    let group: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, value, remarks, enabled, position, group
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeInt(forKey: .id)
        name = try c.decodeString(forKey: .name)
        value = try c.decodeString(forKey: .value)
        remarks = try c.decodeString(forKey: .remarks)
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        position = (try? c.decodeDouble(forKey: .position)) ?? 10000.0
        sortOrder = try c.decodeInt(forKey: .sortOrder)
        group = try c.decodeString(forKey: .group)
        createdAt = try c.decodeDate(forKey: .createdAt)
        updatedAt = try c.decodeDate(forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(value, forKey: .value)
        try c.encode(remarks, forKey: .remarks)
        try c.encode(group, forKey: .group)
    }

    var isPinned: Bool { sortOrder == 1 }
    var groups: [String] {
        group.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

private extension KeyedDecodingContainer {
    func decodeInt(forKey key: Key) throws -> Int {
        if let v = try? decode(Int.self, forKey: key) { return v }
        if let v = try? decode(Double.self, forKey: key) { return Int(v) }
        if let s = try? decode(String.self, forKey: key), let v = Int(s) { return v }
        return 0
    }

    func decodeDouble(forKey key: Key) throws -> Double {
        if let v = try? decode(Double.self, forKey: key) { return v }
        if let v = try? decode(Int.self, forKey: key) { return Double(v) }
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
