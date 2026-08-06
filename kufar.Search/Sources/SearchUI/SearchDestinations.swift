import SwiftUI
import SearchDomain
import SearchInterface
import AnalyticsAPI
import ListingKit

package struct SearchDestinations: ViewModifier {
    private let repo: any SearchRepository
    private let analytics: any AnalyticsTracking
    private let rowAccessory: ListingRowAccessory

    package init(
        repo: any SearchRepository,
        analytics: any AnalyticsTracking,
        rowAccessory: ListingRowAccessory = .none
    ) {
        self.repo = repo
        self.analytics = analytics
        self.rowAccessory = rowAccessory
    }

    package func body(content: Content) -> some View {
        content.navigationDestination(for: SearchRoute.self) { route in
            switch route {
            case .results(let state):
                SearchScreen(filter: state, title: "Результаты",
                             repo: repo, analytics: analytics, rowAccessory: rowAccessory)
            case .filters(let state):
                FiltersScreen(state: state, repo: repo)
            case .sellerListings(let sellerID):
                SearchScreen(filter: FilterState(sellerID: sellerID),
                             title: "Объявления продавца",
                             repo: repo, analytics: analytics, rowAccessory: rowAccessory)
            }
        }
    }
}
