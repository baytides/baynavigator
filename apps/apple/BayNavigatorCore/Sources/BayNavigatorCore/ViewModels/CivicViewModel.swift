import SwiftUI

@Observable
@MainActor
public final class CivicViewModel {
    // City guide
    public private(set) var cityGuide: CityGuide?

    // Representatives
    public private(set) var representatives: RepresentativeList = RepresentativeList()
    public private(set) var isLoadingRepresentatives = false

    // City news
    public private(set) var cityNews: [CityNews] = []
    public private(set) var isLoadingNews = false

    // Error state
    public private(set) var error: String?

    private let civicService = CivicService.shared

    public init() {}

    /// Load all civic data for a location
    public func loadData(cityName: String?, countyName: String?, zipCode: String? = nil) async {
        error = nil

        // Load city guide
        if let cityName = cityName {
            cityGuide = civicService.getCityGuide(cityName: cityName)
        } else {
            cityGuide = nil
        }

        // Load representatives
        await loadRepresentatives(cityName: cityName, countyName: countyName, zipCode: zipCode)

        // Load news
        if let cityName = cityName {
            await loadCityNews(cityName: cityName)
        }
    }

    /// Load representatives for a location
    public func loadRepresentatives(cityName: String?, countyName: String?, zipCode: String? = nil) async {
        isLoadingRepresentatives = true
        defer { isLoadingRepresentatives = false }

        representatives = await civicService.getRepresentatives(
            cityName: cityName,
            countyName: countyName,
            zipCode: zipCode
        )
    }

    /// Load city news
    public func loadCityNews(cityName: String) async {
        isLoadingNews = true
        defer { isLoadingNews = false }

        cityNews = await civicService.getCityNews(cityName: cityName)
    }

    /// Check if a city has a guide available
    public func hasCityGuide(cityName: String?) -> Bool {
        civicService.hasCityGuide(cityName: cityName)
    }
}
