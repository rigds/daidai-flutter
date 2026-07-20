import SwiftUI

struct SponsorView: View {
    @EnvironmentObject var apiService: ApiService
    @StateObject private var viewModel = SponsorViewModel(api: ApiService(baseURL: "", keychain: KeychainStorage.shared))

    var body: some View {
        GlassScaffold {
            Group {
                if viewModel.isLoading && viewModel.sponsors.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    contentView
                }
            }
        }
        .navigationTitle("赞助者")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.updateAPI(apiService)
            await viewModel.load()
        }
        .refreshable { await viewModel.load() }
    }

    private var contentView: some View {
        List {
            // Total section
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.error)
                    Text("累计赞助")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("¥\(viewModel.totalAmount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Sponsors list
            Section("赞助记录") {
                if viewModel.sponsors.isEmpty {
                    HStack {
                        Spacer()
                        Text("暂无赞助记录")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.sponsors) { sponsor in
                        SponsorRow(sponsor: sponsor)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Sponsor Row

struct SponsorRow: View {
    let sponsor: Sponsor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.title2)
                .foregroundColor(AppColors.error.opacity(0.7))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sponsor.name)
                        .font(.headline)
                    Spacer()
                    Text("¥\(sponsor.amount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary)
                }
                if let message = sponsor.message, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let date = sponsor.date {
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(AppColors.slate400)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
