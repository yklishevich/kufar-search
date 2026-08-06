import SwiftUI
import SearchDomain
import SearchInterface
import GoodsInterface
import AutoInterface
import Navigation
import ListingKit
import SharedKernel

/// Избранное — вторая общая поверхность: в нём тоже лежат объявления
/// разных вертикалей. Живёт в поиске по той же причине, что и лента.
package struct FavoritesScreen: View {
    @Environment(Router.self) private var router
    @State private var items: [ListingRef] = []

    private let repo: any SearchRepository
    private let rowAccessory: ListingRowAccessory

    package init(repo: any SearchRepository, rowAccessory: ListingRowAccessory = .none) {
        self.repo = repo
        self.rowAccessory = rowAccessory
    }

    package var body: some View {
        List(items) { ref in
            Button {
                switch ref.vertical {
                case .goods: router.push(GoodsRoute.details(ref.id))
                case .auto:  router.push(AutoRoute.details(ref.id))
                }
            } label: {
                ListingRow(ref: ref, showsVerticalBadge: true) {
                    rowAccessory.view(for: ref)
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .navigationTitle("Избранное")
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("Пока пусто", systemImage: "heart")
            }
        }
        .task { items = (try? await repo.favorites()) ?? [] }
    }
}
