// swift-tools-version: 5.9
import PackageDescription

// Дерево категорий. Отдельный пакет появился, когда у него возник второй
// потребитель: подача объявления берёт ту же категорию, что и фильтр поиска.
//
// Правило простое: как только контракт нужен двум командам, он перестаёт
// принадлежать одной из них и переезжает в свой пакет. До этого момента
// выносить его — оверинжиниринг.

let package = Package(
    name: "KufarCatalogContracts",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "CatalogContracts", targets: ["CatalogContracts"])
    ],
    dependencies: [
        .package(id: "kufar.Foundation", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CatalogContracts",
            dependencies: [
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        )
    ]
)
