import Foundation

enum ApiUtils {
    static func extractData<T: Codable>(from data: Data, type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            return DateParser.parse(dateString) ?? Date()
        }
        return try decoder.decode(type, from: data)
    }

    static func extractApiResponse<T: Codable>(from data: Data, dataType: T.Type) throws -> ApiResponse<T> {
        try extractData(from: data, type: ApiResponse<T>.self)
    }

    static func extractPaginated<T: Codable>(from data: Data, itemType: T.Type) throws -> PaginatedData<T> {
        try extractData(from: data, type: PaginatedData<T>.self)
    }

    static func extractErrorMessage(from error: Error) -> String {
        if let apiError = error as? ApiError {
            return apiError.localizedDescription
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet: return "网络连接不可用"
            case .timedOut: return "请求超时"
            case .cannotFindHost: return "无法连接到服务器"
            case .cannotConnectToHost: return "无法连接到服务器"
            case .networkConnectionLost: return "网络连接已断开"
            default: return "网络错误: \(urlError.localizedDescription)"
            }
        }
        return error.localizedDescription
    }

    static func decodeJSON<T: Codable>(_ jsonString: String?, type: T.Type) -> T? {
        guard let jsonString, let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func encodeJSON<T: Codable>(_ value: T) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
