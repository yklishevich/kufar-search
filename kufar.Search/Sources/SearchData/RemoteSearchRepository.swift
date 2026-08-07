import Foundation
import SearchDomain
import SearchInterface
import CatalogContracts
import NetworkingInterface
import SharedKernel

package struct RemoteSearchRepository: SearchRepository {
    private let client: any HTTPPerforming

    package init(client: any HTTPPerforming) {
        self.client = client
    }

    package func categories() async throws -> [CatalogCategory] {
        _ = try? await client.get("catalog/categories")
        return Self.tree
    }

    package func filterSchema(categoryID: CatalogCategory.ID?) async throws -> Data {
        _ = try? await client.get("catalog/\(categoryID ?? "root")/filters")
        return Self.schema(for: categoryID)
    }

    package func search(_ state: FilterState, page: Int) async throws -> SearchResults {
        _ = try? await client.get("search?page=\(page)")
        try? await Task.sleep(for: .milliseconds(200))
        return Self.results(state: state, page: page)
    }

    package func favorites() async throws -> [ListingRef] {
        _ = try? await client.get("favorites")
        return [Self.goodsItems[0], Self.autoItems[1]]
    }
}
