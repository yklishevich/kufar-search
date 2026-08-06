import SwiftUI
import Observation
import Combine
import SearchDomain
import SearchInterface
import CatalogContracts
import GoodsInterface
import AutoInterface
import AnalyticsAPI
import Navigation
import ListingKit
import DesignComponents
import DesignTokens
import SharedKernel

@MainActor
@Observable
final class SearchModel {
    private let repo: any SearchRepository
    private let analytics: any AnalyticsTracking

    var filter: FilterState
    private(set) var items: [ListingRef] = []
    private(set) var total = 0
    private(set) var isLoading = false
    private(set) var categories: [CatalogCategory] = []
    private var nextPage: Int? = 0

    init(filter: FilterState, repo: any SearchRepository, analytics: any AnalyticsTracking) {
        self.filter = filter
        self.repo = repo
        self.analytics = analytics
    }

    var categoryTitle: String {
        categories.find(filter.categoryID)?.title ?? "Все категории"
    }

    func start() async {
        categories = (try? await repo.categories()) ?? []
        await reload()
    }

    /// Меняется запрос или фильтр — выдача начинается заново.
    func apply(_ new: FilterState) async {
        guard new != filter else { return }
        filter = new
        await reload()
    }

    func reload() async {
        nextPage = 0
        items = []
        await loadNextPage()
    }

    func loadNextPage() async {
        guard let page = nextPage, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        guard let results = try? await repo.search(filter, page: page) else { return }
        items.append(contentsOf: results.items)
        total = results.total
        nextPage = results.nextPage
        analytics.track(AnalyticsEvent(name: "search_performed", parameters: [
            "category": filter.categoryID ?? "all",
            "query": filter.query,
            "page": String(page)
        ]))
    }

    func loadMoreIfNeeded(after ref: ListingRef) async {
        guard let index = items.firstIndex(of: ref), index >= items.count - 2 else { return }
        await loadNextPage()
    }
}

/// Единая лента площадки: строка поиска сверху, кнопка фильтров справа,
/// результаты всех вертикалей вперемешку.
///
/// Вертикаль выбирается КАТЕГОРИЕЙ в фильтре, а не вкладкой. Поэтому
/// вертикалей в табах нет — есть один поиск.
package struct SearchScreen: View {
    @Environment(Router.self) private var router
    @State private var model: SearchModel

    private let title: String
    private let rowAccessory: ListingRowAccessory

    package init(
        filter: FilterState = .empty,
        title: String = "Поиск",
        repo: any SearchRepository,
        analytics: any AnalyticsTracking,
        // Дефолт здесь допустим, в отличие от репозитория (3.1): `.none`
        // нейтрален и не тянет ни сети, ни прод-эндпоинта. Забыл передать —
        // получил ленту без акцессоров, а не живой трафик в превью.
        rowAccessory: ListingRowAccessory = .none
    ) {
        self.title = title
        self.rowAccessory = rowAccessory
        _model = State(wrappedValue: SearchModel(filter: filter, repo: repo, analytics: analytics))
    }

    package var body: some View {
        List {
            Section {
                ForEach(model.items) { ref in
                    Button { open(ref) } label: {
                        // Content у ForEach один на всю коллекцию, поэтому строка
                        // обязана быть одного типа для всех вертикалей. Различается
                        // только акцессор — и различие приезжает фабрикой из корня,
                        // а не импортом чужой вертикали.
                        ListingRow(ref: ref, showsVerticalBadge: model.filter.categoryID == nil) {
                            rowAccessory.view(for: ref)
                        }
                    }
                    .buttonStyle(.plain)
                    .task { await model.loadMoreIfNeeded(after: ref) }
                }
                if model.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            } header: {
                Text("\(model.categoryTitle) · \(model.total) объявлений")
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .searchable(text: searchText, prompt: "Что ищете?")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.push(SearchRoute.filters(model.filter))
                } label: {
                    Label("Фильтры", systemImage: model.filter.activeCount > 0
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task { await model.start() }
        // Экран фильтров возвращает новое состояние через тот же маршрут.
        .onReceive(FilterBus.shared.published) { new in
            Task { await model.apply(new) }
        }
    }

    private var searchText: Binding<String> {
        Binding(
            get: { model.filter.query },
            set: { new in
                var updated = model.filter
                updated.query = new
                Task { await model.apply(updated) }
            }
        )
    }

    /// ЕДИНСТВЕННОЕ место в приложении, которое знает про все вертикали сразу.
    ///
    /// Вертикаль приезжает данными в ListingRef, в маршрут превращается здесь.
    /// Добавится вертикаль — компилятор придёт ровно в эту строку.
    /// Ни одного import чужой реализации: только контракты.
    private func open(_ ref: ListingRef) {
        switch ref.vertical {
        case .goods:
            router.push(GoodsRoute.details(ref.id))
        case .auto:
            router.push(AutoRoute.details(ref.id))
        }
    }
}
