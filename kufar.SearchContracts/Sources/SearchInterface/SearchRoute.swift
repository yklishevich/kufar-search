import Foundation
import SharedKernel
import CatalogContracts

/// Контракт поиска. Data-only, Foundation.
///
/// Поиск — общая поверхность площадки: лента одна на все вертикали,
/// а вертикаль выбирается категорией в фильтре. Поэтому маршруты поиска
/// нужны и вертикалям (кнопка «другие объявления продавца»),
/// и профилю, и корню приложения.
public enum SearchRoute: Hashable, Codable, Sendable, CaseIterable {
    /// Результаты по состоянию фильтра.
    case results(FilterState)
    /// Экран фильтров: категория плюс server-driven поля.
    case filters(FilterState)
    /// Всё, что продаёт этот продавец, — во всех вертикалях сразу.
    case sellerListings(User.ID)

    public static var allCases: [SearchRoute] {
        [.results(.empty), .filters(.empty), .sellerListings("sample")]
    }
}

/// Состояние фильтра целиком. Codable, потому что уезжает в NavigationPath
/// и в сохранённые поиски.
public struct FilterState: Hashable, Codable, Sendable {
    public var query: String
    public var categoryID: CatalogCategory.ID?
    /// id поля из схемы → значение. Состав полей задаёт бэкенд.
    public var values: [String: AttributeValue]
    public var sellerID: User.ID?

    public init(
        query: String = "",
        categoryID: CatalogCategory.ID? = nil,
        values: [String: AttributeValue] = [:],
        sellerID: User.ID? = nil
    ) {
        self.query = query
        self.categoryID = categoryID
        self.values = values
        self.sellerID = sellerID
    }

    public static let empty = FilterState()

    /// Сколько условий показать бейджем на кнопке фильтров.
    public var activeCount: Int {
        values.count + (categoryID == nil ? 0 : 1)
    }
}
