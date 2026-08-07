import SwiftUI
import SearchData
import SearchDomain
import SearchUI
import AnalyticsAPI
import NetworkingInterface
import ListingKit

/// Наружу торчит только это. SearchUI, SearchData и SearchDomain
/// не объявлены продуктами — SwiftPM не даст их импортировать
/// ни одной чужой команде.
public enum SearchAssembly {

    public static func makeRepository(client: any HTTPPerforming) -> any SearchRepository {
        RemoteSearchRepository(client: client)
    }

    /// `rowAccessory` без дефолта намеренно: состав вертикалей знает только
    /// composition root, и умолчание здесь означало бы «лента молча потеряла
    /// акцессоры, потому что кто-то забыл аргумент».
    public static func makeDestinations(
        repo: any SearchRepository,
        analytics: any AnalyticsTracking,
        rowAccessory: ListingRowAccessory
    ) -> some ViewModifier {
        SearchDestinations(repo: repo, analytics: analytics, rowAccessory: rowAccessory)
    }

    @MainActor
    public static func makeSearchScreen(
        repo: any SearchRepository,
        analytics: any AnalyticsTracking,
        rowAccessory: ListingRowAccessory
    ) -> some View {
        SearchScreen(repo: repo, analytics: analytics, rowAccessory: rowAccessory)
    }

    @MainActor
    public static func makeFavoritesScreen(
        repo: any SearchRepository,
        rowAccessory: ListingRowAccessory
    ) -> some View {
        FavoritesScreen(repo: repo, rowAccessory: rowAccessory)
    }
}
