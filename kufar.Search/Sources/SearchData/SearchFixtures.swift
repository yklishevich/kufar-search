import Foundation
import SearchDomain
import SearchInterface
import CatalogContracts
import SharedKernel

extension RemoteSearchRepository {

    /// Дерево категорий с бэкенда. Вертикаль — поле узла: клиент её
    /// не вычисляет и не хардкодит.
    static let tree: [CatalogCategory] = [
        CatalogCategory(id: "goods", title: "Товары", vertical: .goods, children: [
            CatalogCategory(id: "goods.electronics", title: "Электроника", vertical: .goods),
            CatalogCategory(id: "goods.furniture", title: "Мебель и интерьер", vertical: .goods)
        ]),
        CatalogCategory(id: "auto", title: "Транспорт", vertical: .auto, children: [
            CatalogCategory(id: "auto.cars", title: "Легковые автомобили", vertical: .auto),
            CatalogCategory(id: "auto.parts", title: "Запчасти", vertical: .auto)
        ])
    ]

    /// Разные категории — разные поля фильтра. Ровно то, ради чего схема
    /// приходит с сервера: «объём двигателя» не хардкодится в клиенте.
    ///
    /// В схеме авто последнее поле неизвестного типа: проверка фолбэка,
    /// без которого новое поле на бэке роняет старые сборки.
    static func schema(for categoryID: CatalogCategory.ID?) -> Data {
        switch categoryID {
        case "auto", "auto.cars":
            Data("""
            [
              { "id": "brand",   "title": "Марка",      "type": "reference",
                "options": ["Volkswagen", "Skoda", "Renault", "Mazda"] },
              { "id": "year",    "title": "Год от",     "type": "number" },
              { "id": "mileage", "title": "Пробег до",  "type": "number", "unit": "км" },
              { "id": "customs", "title": "Растаможен", "type": "toggle" },
              { "id": "eco",     "title": "Эко-класс",  "type": "gauge" }
            ]
            """.utf8)
        case "goods", "goods.electronics", "goods.furniture":
            Data("""
            [
              { "id": "state",    "title": "Состояние", "type": "reference",
                "options": ["Новое", "Б/у"] },
              { "id": "delivery", "title": "С доставкой", "type": "toggle" },
              { "id": "priceMax", "title": "Цена до",   "type": "number", "unit": "р." }
            ]
            """.utf8)
        default:
            Data("""
            [
              { "id": "priceMax", "title": "Цена до", "type": "number", "unit": "р." }
            ]
            """.utf8)
        }
    }

    static let goodsItems: [ListingRef] = [
        ListingRef(id: ListingID("g-1"), vertical: .goods,
                   title: "Пылесос Bosch, почти новый", price: Money(amount: 190)),
        ListingRef(id: ListingID("g-2"), vertical: .goods,
                   title: "Кресло компьютерное", price: Money(amount: 120)),
        ListingRef(id: ListingID("g-3"), vertical: .goods,
                   title: "Велосипед горный 26\"", price: Money(amount: 310)),
        ListingRef(id: ListingID("g-4"), vertical: .goods,
                   title: "Стол письменный, дуб", price: Money(amount: 240))
    ]

    static let autoItems: [ListingRef] = [
        ListingRef(id: ListingID("a-1"), vertical: .auto,
                   title: "Volkswagen Golf VII, 2016", price: Money(amount: 34_500)),
        ListingRef(id: ListingID("a-2"), vertical: .auto,
                   title: "Skoda Octavia A7, 2018", price: Money(amount: 41_200)),
        ListingRef(id: ListingID("a-3"), vertical: .auto,
                   title: "Renault Logan, 2014", price: Money(amount: 18_900))
    ]

    static func results(state: FilterState, page: Int) -> SearchResults {
        let category = tree.find(state.categoryID)

        var pool: [ListingRef]
        switch category?.vertical {
        case .goods: pool = goodsItems
        case .auto:  pool = autoItems
        case nil:    pool = goodsItems + autoItems      // без категории — всё сразу
        }

        if state.sellerID != nil {
            // Один продавец, две вертикали — обычное дело на классифайде.
            pool = [goodsItems[1], autoItems[0]]
        }

        if !state.query.isEmpty {
            pool = pool.filter { $0.title.localizedCaseInsensitiveContains(state.query) }
        }

        let paged = pool.map { ref in
            page == 0 ? ref : ListingRef(id: ListingID("\(ref.id.rawValue)-p\(page)"),
                                         vertical: ref.vertical,
                                         title: ref.title,
                                         price: ref.price)
        }
        return SearchResults(items: paged, total: pool.count * 3,
                             nextPage: page < 2 ? page + 1 : nil)
    }
}
