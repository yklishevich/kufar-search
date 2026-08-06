// swift-tools-version: 5.9
import PackageDescription

// Контракты поиска: маршруты, состояние фильтра, категория.
// Отдельный пакет с одной-единственной зависимостью — SharedKernel.
// Кто подключает его, не тянет ни SwiftUI, ни дизайн-систему.

let package = Package(
    name: "KufarSearchContracts",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SearchInterface", targets: ["SearchInterface"])
    ],
    dependencies: [
        .package(id: "kufar.CatalogContracts", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SearchInterface",
            dependencies: [
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts"),
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        )
    ]
)
