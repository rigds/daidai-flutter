import Foundation

struct ApiResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?

    var isSuccess: Bool { code == 200 }

    enum CodingKeys: String, CodingKey {
        case code, message, data
    }
}

struct PaginatedData<T: Codable>: Codable {
    let items: [T]
    let total: Int

    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }

    enum CodingKeys: String, CodingKey {
        case items, total
    }
}

struct EmptyData: Codable {}
