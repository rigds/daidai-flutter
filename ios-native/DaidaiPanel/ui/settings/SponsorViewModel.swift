import Foundation

struct Sponsor: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let message: String?
    let date: String?
}

@MainActor
final class SponsorViewModel: ObservableObject {
    @Published var sponsors: [Sponsor] = []
    @Published var totalAmount: String = ""
    @Published var isLoading = false
    @Published var error: String?

    private var api: ApiService

    init(api: ApiService) {
        self.api = api
    }

    func updateAPI(_ api: ApiService) {
        self.api = api
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            let response: ApiResponse<[String: AnyCodable]> = try await api.sponsors()
            if let data = response.data {
                var list: [Sponsor] = []
                if let items = data["items"]?.value as? [[String: Any]] {
                    for item in items {
                        list.append(Sponsor(
                            name: (item["name"] as? String) ?? "匿名",
                            amount: (item["amount"] as? String) ?? "0",
                            message: item["message"] as? String,
                            date: item["date"] as? String
                        ))
                    }
                }
                self.sponsors = list
                self.totalAmount = (data["total"]?.value as? String) ?? "0"
            }
        } catch {
            self.error = ApiUtils.extractErrorMessage(from: error)
        }
        isLoading = false
    }
}
