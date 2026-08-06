import Foundation
import SharedKernel

/// Узел дерева категорий.
///
/// Здесь категория превращается в вертикаль — и это единственное место,
/// где такое превращение вообще происходит. Дерево приходит с бэкенда,
/// поэтому новая категория не требует релиза; новая ВЕРТИКАЛЬ требует,
/// потому что для неё нужен модуль с карточкой.
///
/// Имя с префиксом намеренно: `Category` — слишком частое слово,
/// а публичный тип контрактного пакета попадает в область видимости
/// половины кодовой базы и легко становится неоднозначным.
public struct CatalogCategory: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = String

    public let id: ID
    public let title: String
    public let vertical: Vertical
    public let children: [CatalogCategory]

    public init(id: ID, title: String, vertical: Vertical, children: [CatalogCategory] = []) {
        self.id = id
        self.title = title
        self.vertical = vertical
        self.children = children
    }

    /// Лист дерева — та категория, в которой реально живут объявления.
    public var isLeaf: Bool { children.isEmpty }
}

public extension Array where Element == CatalogCategory {
    /// Плоский обход — нужен и пикеру, и резолву вертикали.
    func flattened() -> [CatalogCategory] {
        flatMap { [$0] + $0.children.flattened() }
    }

    func find(_ id: CatalogCategory.ID?) -> CatalogCategory? {
        guard let id else { return nil }
        return flattened().first { $0.id == id }
    }
}
