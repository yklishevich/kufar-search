// swift-tools-version: 5.9
import PackageDescription

// Единственный модуль приложения, который знает про ВСЕ вертикали сразу —
// потому что лента и фильтры общие. Знает только их контракты.
//
// Наружу торчит один продукт Search. SearchUI, SearchData и SearchDomain
// остаются внутренними таргетами: чужая команда не сможет их импортировать,
// это запрещает SwiftPM, а не договорённость.

let package = Package(
    name: "KufarSearch",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Search", targets: ["Search"])
    ],
    dependencies: [
        .package(id: "kufar.CatalogContracts", from: "1.0.0"),
        .package(id: "kufar.SearchContracts", from: "1.0.0"),
        .package(id: "kufar.GoodsContracts", from: "1.0.0"),
        .package(id: "kufar.AutoContracts", from: "1.0.0"),
        .package(id: "kufar.Foundation", from: "1.0.0"),
        .package(id: "kufar.Navigation", from: "1.0.0"),
        .package(id: "kufar.Analytics", from: "1.0.0"),
        .package(id: "kufar.DesignTokens", from: "1.0.0"),
        .package(id: "kufar.DesignComponents", from: "1.0.0"),
        .package(id: "kufar.SchemaKit", from: "1.0.0"),
        .package(id: "kufar.ListingKit", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SearchDomain",
            dependencies: [
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts"),
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                .product(name: "SearchInterface", package: "kufar.SearchContracts")
            ]
        ),
        .target(
            name: "SearchData",
            dependencies: [
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts"),
                "SearchDomain",
                .product(name: "Networking", package: "kufar.Foundation"),
                .product(name: "SharedKernel", package: "kufar.Foundation"),
                .product(name: "SearchInterface", package: "kufar.SearchContracts")
            ]
        ),
        .target(
            name: "SearchUI",
            dependencies: [
                .product(name: "CatalogContracts", package: "kufar.CatalogContracts"),
                "SearchDomain",
                .product(name: "SearchInterface", package: "kufar.SearchContracts"),
                .product(name: "GoodsInterface", package: "kufar.GoodsContracts"),
                .product(name: "AutoInterface", package: "kufar.AutoContracts"),
                .product(name: "Navigation", package: "kufar.Navigation"),
                .product(name: "DesignTokens", package: "kufar.DesignTokens"),
                .product(name: "DesignComponents", package: "kufar.DesignComponents"),
                .product(name: "SchemaKit", package: "kufar.SchemaKit"),
                .product(name: "ListingKit", package: "kufar.ListingKit"),
                .product(name: "AnalyticsAPI", package: "kufar.Analytics"),
                .product(name: "SharedKernel", package: "kufar.Foundation")
            ]
        ),
        .target(
            name: "Search",
            dependencies: [
                "SearchUI",
                "SearchData",
                "SearchDomain",
                .product(name: "AnalyticsAPI", package: "kufar.Analytics"),
                .product(name: "Networking", package: "kufar.Foundation"),
                // Тип фабрики акцессора — часть публичной сигнатуры ассамблеи.
                .product(name: "ListingKit", package: "kufar.ListingKit")
            ]
        )
    ]
)
