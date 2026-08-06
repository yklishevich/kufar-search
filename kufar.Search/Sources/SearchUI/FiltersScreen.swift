import SwiftUI
import Combine
import Observation
import SearchDomain
import SearchInterface
import CatalogContracts
import Navigation
import SchemaKit
import DesignComponents
import DesignTokens
import SharedKernel

/// Экран фильтров возвращает результат назад в ленту.
///
/// Через шину, а не через биндинг: экраны лежат в разных элементах
/// NavigationPath и общего владельца состояния у них нет. Альтернатива —
/// поднять FilterState в модель таба; для демо шина короче и честно
/// показывает, что это осознанный выбор, а не единственный вариант.
@MainActor
final class FilterBus {
    static let shared = FilterBus()
    private let subject = PassthroughSubject<FilterState, Never>()

    var published: AnyPublisher<FilterState, Never> { subject.eraseToAnyPublisher() }

    func publish(_ state: FilterState) { subject.send(state) }
}

@MainActor
@Observable
final class FiltersModel {
    private let repo: any SearchRepository

    var draft: FilterState
    private(set) var categories: [CatalogCategory] = []
    private(set) var fields: [SchemaField] = []
    private(set) var matches: Int?

    init(state: FilterState, repo: any SearchRepository) {
        self.draft = state
        self.repo = repo
    }

    func start() async {
        categories = (try? await repo.categories()) ?? []
        await reloadSchema()
    }

    /// Смена категории меняет НАБОР полей — он приходит с бэкенда.
    /// Значения полей прошлой категории сбрасываются: они бессмысленны.
    func select(_ categoryID: CatalogCategory.ID?) async {
        draft.categoryID = categoryID
        draft.values = [:]
        await reloadSchema()
    }

    func reloadSchema() async {
        guard let data = try? await repo.filterSchema(categoryID: draft.categoryID) else { return }
        fields = (try? JSONDecoder().decode([SchemaField].self, from: data)) ?? []
        await recount()
    }

    func recount() async {
        matches = (try? await repo.search(draft, page: 0))?.total
    }
}

struct FiltersScreen: View {
    @Environment(Router.self) private var router
    @State private var model: FiltersModel

    init(state: FilterState, repo: any SearchRepository) {
        _model = State(wrappedValue: FiltersModel(state: state, repo: repo))
    }

    var body: some View {
        Form {
            Section("Категория") {
                Button("Все категории") { Task { await model.select(nil) } }
                ForEach(model.categories) { root in
                    CategoryRowView(category: root, selected: model.draft.categoryID) { id in
                        Task { await model.select(id) }
                    }
                }
            }

            Section("Параметры") {
                // Состав полей задаёт сервер. Клиент умеет рисовать каталог
                // примитивов — и ничего не знает про «объём двигателя».
                SchemaForm(fields: model.fields, values: valuesBinding)
                if model.fields.isEmpty {
                    Text("Для этой категории параметров нет")
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
        .navigationTitle("Фильтры")
        .task { await model.start() }
        .onChange(of: model.draft.values) { _, _ in
            Task { await model.recount() }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(showTitle, systemImage: "checkmark") {
                FilterBus.shared.publish(model.draft)
                router.pop()
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background(.bar)
        }
    }

    private var showTitle: String {
        guard let matches = model.matches else { return "Показать" }
        return "Показать \(matches)"
    }

    private var valuesBinding: Binding<[String: AttributeValue]> {
        Binding(get: { model.draft.values }, set: { model.draft.values = $0 })
    }
}

struct CategoryRowView: View {
    let category: CatalogCategory
    let selected: CatalogCategory.ID?
    let onSelect: (CatalogCategory.ID) -> Void

    var body: some View {
        DisclosureGroup {
            ForEach(category.children) { child in
                Button {
                    onSelect(child.id)
                } label: {
                    HStack {
                        Text(child.title)
                        Spacer()
                        if selected == child.id {
                            Image(systemName: "checkmark").foregroundStyle(Palette.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } label: {
            Button {
                onSelect(category.id)
            } label: {
                HStack {
                    Text(category.title)
                    Spacer()
                    if selected == category.id {
                        Image(systemName: "checkmark").foregroundStyle(Palette.accent)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
