import Foundation
import SharedKernel
import SearchInterface
import CatalogContracts

public struct SearchResults: Hashable, Sendable {
    public let items: [ListingRef]
    public let total: Int
    public let nextPage: Int?

    public init(items: [ListingRef], total: Int, nextPage: Int?) {
        self.items = items
        self.total = total
        self.nextPage = nextPage
    }
}

/// Репозиторий общей ленты. Возвращает ListingRef — ссылку с вертикалью
/// внутри, потому что в одной выдаче могут лежать и товары, и авто.
public protocol SearchRepository: Sendable {
    func categories() async throws -> [CatalogCategory]
    /// Схема полей фильтра для выбранной категории. Состав задаёт бэкенд.
    func filterSchema(categoryID: CatalogCategory.ID?) async throws -> Data
    func search(_ state: FilterState, page: Int) async throws -> SearchResults
    func favorites() async throws -> [ListingRef]
}
