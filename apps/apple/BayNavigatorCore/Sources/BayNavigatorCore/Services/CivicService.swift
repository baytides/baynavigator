import Foundation

/// Service for fetching civic data: city guides, news, representatives
@MainActor
public final class CivicService: Sendable {
    public static let shared = CivicService()

    private let cache: CacheService
    private let newsCacheDuration: TimeInterval = 30 * 60 // 30 minutes
    private let requestTimeout: TimeInterval = 10
    private let torRequestTimeout: TimeInterval = 30 // Tor is slower

    private init() {
        self.cache = CacheService.shared
    }

    // MARK: - Tor Integration

    /// Get the appropriate URLSession based on Tor status
    private func getSession() async -> URLSession {
        let safetyService = SafetyService.shared
        let torEnabled = await safetyService.isTorEnabled()

        if torEnabled {
            let proxyAvailable = await safetyService.isOrbotProxyAvailable()
            if proxyAvailable {
                let config = safetyService.createTorProxyConfiguration()
                config.timeoutIntervalForRequest = torRequestTimeout
                config.timeoutIntervalForResource = torRequestTimeout
                return URLSession(configuration: config)
            }
        }

        // Fall back to standard session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        return URLSession(configuration: config)
    }

    // MARK: - City Guide

    /// Get city guide for a given city
    public func getCityGuide(cityName: String) -> CityGuide? {
        let key = cityName.lowercased()
        return Self.supportedCityGuides[key]
    }

    /// Check if a city has a guide available
    public func hasCityGuide(cityName: String?) -> Bool {
        guard let cityName = cityName, !cityName.isEmpty else { return false }
        return Self.supportedCityGuides.keys.contains(cityName.lowercased())
    }

    /// List of supported cities
    public var supportedCities: [String] {
        Self.supportedCityGuides.keys.sorted()
    }

    // MARK: - City News

    /// Get news for a city (fetches from API if available)
    public func getCityNews(cityName: String) async -> [CityNews] {
        guard let guide = getCityGuide(cityName: cityName),
              let newsUrl = guide.newsRssUrl else {
            return []
        }

        // Try to fetch from API
        do {
            return try await fetchCityNews(from: newsUrl, source: cityName)
        } catch {
            return []
        }
    }

    private func fetchCityNews(from urlString: String, source: String) async throws -> [CityNews] {
        guard let url = URL(string: urlString) else { return [] }

        let session = await getSession()
        let (data, _) = try await session.data(from: url)

        // Try to parse as JSON
        if let newsItems = try? JSONDecoder().decode([CityNewsDTO].self, from: data) {
            return newsItems.map { dto in
                CityNews(
                    title: dto.title,
                    summary: dto.summary ?? dto.description ?? "",
                    url: dto.url ?? dto.link ?? "",
                    publishedAt: ISO8601DateFormatter().date(from: dto.date ?? "") ?? Date(),
                    imageUrl: dto.image,
                    source: source
                )
            }
        }

        return []
    }

    // MARK: - Representatives

    /// Get representatives for a location
    public func getRepresentatives(
        cityName: String?,
        countyName: String?,
        zipCode: String? = nil
    ) async -> RepresentativeList {
        var federal: [Representative] = []
        var state: [Representative] = []
        var local: [Representative] = []

        // California US Senators (statewide, always shown)
        federal.append(contentsOf: Self.californiaUSsenators)

        // Get county key for lookups
        var countyKey = countyName?.lowercased()
        if countyKey?.hasSuffix(" county") == true {
            countyKey = String(countyKey!.dropLast(7))
        }

        // Add US House representatives by county
        if let countyKey = countyKey,
           let countyReps = Self.usHouseByCounty[countyKey] {
            if let zipCode = zipCode,
               let district = getCongressionalDistrict(for: zipCode) {
                // Filter to specific district if we have zip code
                let filtered = countyReps.filter { rep in
                    rep.district?.contains("District \(district)") == true
                }
                federal.append(contentsOf: filtered.isEmpty ? countyReps : filtered)
            } else {
                federal.append(contentsOf: countyReps)
            }
        }

        // Add State Legislature by county
        if let countyKey = countyKey,
           let stateReps = Self.stateLegislatureByCounty[countyKey] {
            if let zipCode = zipCode {
                let assemblyDistrict = getAssemblyDistrict(for: zipCode)
                let senateDistrict = getSenateDistrict(for: zipCode)

                let filtered = stateReps.filter { rep in
                    if rep.title == "Assembly Member", let ad = assemblyDistrict {
                        return rep.district?.contains("District \(ad)") == true
                    }
                    if rep.title == "State Senator", let sd = senateDistrict {
                        return rep.district?.contains("District \(sd)") == true
                    }
                    return false
                }
                state.append(contentsOf: filtered.isEmpty ? stateReps : filtered)
            } else {
                state.append(contentsOf: stateReps)
            }
        }

        // Add local officials by city
        if let cityName = cityName,
           let cityOfficials = Self.localOfficialsByCity[cityName.lowercased()] {
            local.append(contentsOf: cityOfficials)
        }

        return RepresentativeList(federal: federal, state: state, local: local)
    }

    // MARK: - District Lookups

    private func getCongressionalDistrict(for zipCode: String) -> String? {
        Self.zipToCongressional[zipCode]
    }

    private func getAssemblyDistrict(for zipCode: String) -> String? {
        Self.zipToAssembly[zipCode]
    }

    private func getSenateDistrict(for zipCode: String) -> String? {
        Self.zipToSenate[zipCode]
    }
}

// MARK: - DTO for News Parsing

private struct CityNewsDTO: Codable {
    let title: String
    let summary: String?
    let description: String?
    let url: String?
    let link: String?
    let date: String?
    let image: String?
}

// MARK: - Static Data

extension CivicService {

    // MARK: US Senators

    static let californiaUSsenators: [Representative] = [
        Representative(
            name: "Alex Padilla",
            title: "U.S. Senator",
            level: .federal,
            party: "Democrat",
            phone: "(202) 224-3553",
            email: "senator@padilla.senate.gov",
            website: "https://www.padilla.senate.gov/",
            district: "California"
        ),
        Representative(
            name: "Adam Schiff",
            title: "U.S. Senator",
            level: .federal,
            party: "Democrat",
            phone: "(202) 224-3841",
            email: "senator@schiff.senate.gov",
            website: "https://www.schiff.senate.gov/",
            district: "California"
        ),
    ]

    // MARK: US House by County

    static let usHouseByCounty: [String: [Representative]] = [
        "san mateo": [
            Representative(
                name: "Kevin Mullin",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3531",
                website: "https://kevinmullin.house.gov/",
                district: "District 15"
            ),
        ],
        "santa clara": [
            Representative(
                name: "Zoe Lofgren",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3072",
                website: "https://lofgren.house.gov/",
                district: "District 18"
            ),
            Representative(
                name: "Anna Eshoo",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-8104",
                website: "https://eshoo.house.gov/",
                district: "District 16"
            ),
            Representative(
                name: "Ro Khanna",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2631",
                website: "https://khanna.house.gov/",
                district: "District 17"
            ),
        ],
        "alameda": [
            Representative(
                name: "Barbara Lee",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2661",
                website: "https://lee.house.gov/",
                district: "District 12"
            ),
            Representative(
                name: "Eric Swalwell",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-5065",
                website: "https://swalwell.house.gov/",
                district: "District 14"
            ),
            Representative(
                name: "Ro Khanna",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2631",
                website: "https://khanna.house.gov/",
                district: "District 17"
            ),
        ],
        "san francisco": [
            Representative(
                name: "Nancy Pelosi",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-4965",
                website: "https://pelosi.house.gov/",
                district: "District 11"
            ),
        ],
        "contra costa": [
            Representative(
                name: "Mark DeSaulnier",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-2095",
                website: "https://desaulnier.house.gov/",
                district: "District 10"
            ),
            Representative(
                name: "John Garamendi",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-1880",
                website: "https://garamendi.house.gov/",
                district: "District 8"
            ),
        ],
        "marin": [
            Representative(
                name: "Jared Huffman",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-5161",
                website: "https://huffman.house.gov/",
                district: "District 2"
            ),
        ],
        "sonoma": [
            Representative(
                name: "Jared Huffman",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-5161",
                website: "https://huffman.house.gov/",
                district: "District 2"
            ),
        ],
        "napa": [
            Representative(
                name: "Mike Thompson",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3311",
                website: "https://mikethompson.house.gov/",
                district: "District 4"
            ),
        ],
        "solano": [
            Representative(
                name: "Mike Thompson",
                title: "U.S. Representative",
                level: .federal,
                party: "Democrat",
                phone: "(202) 225-3311",
                website: "https://mikethompson.house.gov/",
                district: "District 4"
            ),
        ],
    ]

    // MARK: State Legislature by County

    static let stateLegislatureByCounty: [String: [Representative]] = [
        "san francisco": [
            Representative(
                name: "Scott Wiener",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(415) 557-1300",
                website: "https://sd11.senate.ca.gov/",
                district: "District 11"
            ),
            Representative(
                name: "Matt Haney",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(415) 557-3013",
                website: "https://a17.asmdc.org/",
                district: "District 17"
            ),
            Representative(
                name: "Phil Ting",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(415) 557-2312",
                website: "https://a19.asmdc.org/",
                district: "District 19"
            ),
        ],
        "alameda": [
            Representative(
                name: "Nancy Skinner",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(510) 286-1333",
                website: "https://sd09.senate.ca.gov/",
                district: "District 9"
            ),
            Representative(
                name: "Buffy Wicks",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(510) 286-1400",
                website: "https://a14.asmdc.org/",
                district: "District 14"
            ),
            Representative(
                name: "Liz Ortega",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(510) 583-8818",
                website: "https://a20.asmdc.org/",
                district: "District 20"
            ),
        ],
        "santa clara": [
            Representative(
                name: "Dave Cortese",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(408) 558-1295",
                website: "https://sd15.senate.ca.gov/",
                district: "District 15"
            ),
            Representative(
                name: "Evan Low",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(408) 371-2802",
                website: "https://a26.asmdc.org/",
                district: "District 26"
            ),
            Representative(
                name: "Ash Kalra",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(408) 277-2088",
                website: "https://a25.asmdc.org/",
                district: "District 25"
            ),
        ],
        "san mateo": [
            Representative(
                name: "Josh Becker",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(650) 212-3313",
                website: "https://sd13.senate.ca.gov/",
                district: "District 13"
            ),
            Representative(
                name: "Diane Papan",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(650) 349-1600",
                website: "https://a21.asmdc.org/",
                district: "District 21"
            ),
        ],
        "contra costa": [
            Representative(
                name: "Steve Glazer",
                title: "State Senator",
                level: .state,
                party: "Democrat",
                phone: "(925) 258-1176",
                website: "https://sd07.senate.ca.gov/",
                district: "District 7"
            ),
            Representative(
                name: "Tim Grayson",
                title: "Assembly Member",
                level: .state,
                party: "Democrat",
                phone: "(925) 521-1511",
                website: "https://a15.asmdc.org/",
                district: "District 15"
            ),
        ],
    ]

    // MARK: Local Officials by City

    static let localOfficialsByCity: [String: [Representative]] = [
        "oakland": [
            Representative(
                name: "Sheng Thao",
                title: "Mayor",
                level: .local,
                phone: "(510) 238-3141",
                website: "https://www.oaklandca.gov/officials/mayor-sheng-thao"
            ),
        ],
        "san francisco": [
            Representative(
                name: "Daniel Lurie",
                title: "Mayor",
                level: .local,
                phone: "(415) 554-6141",
                website: "https://sf.gov/departments/office-mayor"
            ),
        ],
        "san jose": [
            Representative(
                name: "Matt Mahan",
                title: "Mayor",
                level: .local,
                phone: "(408) 535-4800",
                website: "https://www.sanjoseca.gov/your-government/departments-offices/mayor-and-city-council/mayor-matt-mahan"
            ),
        ],
        "berkeley": [
            Representative(
                name: "Jesse Arreguín",
                title: "Mayor",
                level: .local,
                phone: "(510) 981-7100",
                website: "https://berkeleyca.gov/your-government/mayor"
            ),
        ],
        "fremont": [
            Representative(
                name: "Lily Mei",
                title: "Mayor",
                level: .local,
                phone: "(510) 284-4000",
                website: "https://www.fremont.gov/government/mayor-city-council/mayor-lily-mei"
            ),
        ],
    ]

    // MARK: Zip Code to District Mappings (sample)

    static let zipToCongressional: [String: String] = [
        "94102": "11", "94103": "11", "94104": "11", "94105": "11", // SF
        "94601": "12", "94602": "12", "94603": "12", "94605": "12", // Oakland
        "95110": "18", "95111": "18", "95112": "18", "95113": "18", // San Jose
    ]

    static let zipToAssembly: [String: String] = [
        "94102": "17", "94103": "17", // SF
        "94601": "18", "94602": "18", // Oakland
        "95110": "25", "95111": "25", // San Jose
    ]

    static let zipToSenate: [String: String] = [
        "94102": "11", "94103": "11", // SF
        "94601": "9", "94602": "9", // Oakland
        "95110": "15", "95111": "15", // San Jose
    ]

    // MARK: Supported City Guides

    static let supportedCityGuides: [String: CityGuide] = [
        "oakland": CityGuide(
            cityName: "Oakland",
            countyName: "Alameda County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(510) 238-3141",
                    website: "https://www.oaklandca.gov/",
                    address: "1 Frank H. Ogawa Plaza, Oakland, CA 94612",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "public-works",
                    name: "Public Works",
                    description: "Streets, sewers, streetlights, and graffiti removal",
                    phone: "(510) 615-5566",
                    website: "https://www.oaklandca.gov/departments/public-works",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
                CityAgency(
                    id: "housing",
                    name: "Housing & Community Development",
                    description: "Affordable housing, tenant services, rent assistance",
                    phone: "(510) 238-3502",
                    website: "https://www.oaklandca.gov/departments/housing-and-community-development",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "human-services",
                    name: "Human Services",
                    description: "Social services, youth programs, senior services",
                    phone: "(510) 238-3088",
                    website: "https://www.oaklandca.gov/departments/human-services",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Parks & Recreation",
                    description: "Parks, community centers, and recreation programs",
                    phone: "(510) 238-7275",
                    website: "https://www.oaklandca.gov/departments/parks-recreation-and-youth-development",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
                CityAgency(
                    id: "library",
                    name: "Oakland Public Library",
                    description: "Libraries, free programs, and resources",
                    phone: "(510) 238-3134",
                    website: "https://oaklandlibrary.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
            ],
            cityWebsite: "https://www.oaklandca.gov/",
            newsRssUrl: "https://www.oaklandca.gov/api/news.json"
        ),

        "san francisco": CityGuide(
            cityName: "San Francisco",
            countyName: "San Francisco",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city and county government offices",
                    phone: "311",
                    website: "https://sf.gov/",
                    address: "1 Dr Carlton B Goodlett Pl, San Francisco, CA 94102",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "hsa",
                    name: "Human Services Agency",
                    description: "CalFresh, Medi-Cal, CalWORKs, and social services",
                    phone: "(415) 557-5000",
                    website: "https://www.sfhsa.org/",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "mohcd",
                    name: "Housing & Community Development",
                    description: "Affordable housing, rent assistance, first-time homebuyers",
                    phone: "(415) 701-5500",
                    website: "https://sfmohcd.org/",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "dpw",
                    name: "Public Works",
                    description: "Streets, sidewalks, graffiti, and city maintenance",
                    phone: "311",
                    website: "https://www.sfpublicworks.org/",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
                CityAgency(
                    id: "sfpl",
                    name: "SF Public Library",
                    description: "Libraries, free programs, and community resources",
                    phone: "(415) 557-4400",
                    website: "https://sfpl.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "rec-park",
                    name: "Recreation & Parks",
                    description: "Parks, recreation centers, and programs",
                    phone: "(415) 831-2700",
                    website: "https://sfrecpark.org/",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://sf.gov/",
            newsRssUrl: "https://sf.gov/api/news.json"
        ),

        "san jose": CityGuide(
            cityName: "San Jose",
            countyName: "Santa Clara County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(408) 535-3500",
                    website: "https://www.sanjoseca.gov/",
                    address: "200 E Santa Clara St, San Jose, CA 95113",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "housing",
                    name: "Housing Department",
                    description: "Affordable housing, rent assistance, homelessness services",
                    phone: "(408) 535-3860",
                    website: "https://www.sanjoseca.gov/your-government/departments/housing",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "prns",
                    name: "Parks, Recreation & Neighborhood Services",
                    description: "Parks, community centers, and recreation programs",
                    phone: "(408) 535-3500",
                    website: "https://www.sanjoseca.gov/your-government/departments/parks-recreation-neighborhood-services",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
                CityAgency(
                    id: "library",
                    name: "San Jose Public Library",
                    description: "Libraries and free community programs",
                    phone: "(408) 808-2000",
                    website: "https://www.sjpl.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "public-works",
                    name: "Public Works",
                    description: "Streets, sidewalks, and city maintenance",
                    phone: "(408) 535-3850",
                    website: "https://www.sanjoseca.gov/your-government/departments/public-works",
                    iconName: "hammer.fill",
                    colorHex: "#FF6F00"
                ),
            ],
            cityWebsite: "https://www.sanjoseca.gov/",
            newsRssUrl: "https://www.sanjoseca.gov/api/news.json"
        ),

        "berkeley": CityGuide(
            cityName: "Berkeley",
            countyName: "Alameda County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(510) 981-2489",
                    website: "https://berkeleyca.gov/",
                    address: "2180 Milvia St, Berkeley, CA 94704",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "hhcs",
                    name: "Health, Housing & Community Services",
                    description: "Social services, housing assistance, and health programs",
                    phone: "(510) 981-5400",
                    website: "https://berkeleyca.gov/your-government/our-work/health-housing-community-services",
                    iconName: "house.fill",
                    colorHex: "#1976D2"
                ),
                CityAgency(
                    id: "library",
                    name: "Berkeley Public Library",
                    description: "Libraries and community programs",
                    phone: "(510) 981-6100",
                    website: "https://www.berkeleypubliclibrary.org/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Parks, Recreation & Waterfront",
                    description: "Parks, pools, and recreation programs",
                    phone: "(510) 981-6700",
                    website: "https://berkeleyca.gov/your-government/our-work/parks-recreation-waterfront",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://berkeleyca.gov/"
        ),

        "fremont": CityGuide(
            cityName: "Fremont",
            countyName: "Alameda County",
            agencies: [
                CityAgency(
                    id: "city-hall",
                    name: "City Hall",
                    description: "Main city government offices",
                    phone: "(510) 284-4000",
                    website: "https://www.fremont.gov/",
                    address: "3300 Capitol Ave, Fremont, CA 94538",
                    iconName: "building.columns.fill",
                    colorHex: "#2E7D32"
                ),
                CityAgency(
                    id: "human-services",
                    name: "Human Services",
                    description: "Family Resource Center, senior services, youth programs",
                    phone: "(510) 574-2000",
                    website: "https://www.fremont.gov/government/departments/human-services",
                    iconName: "person.3.fill",
                    colorHex: "#7B1FA2"
                ),
                CityAgency(
                    id: "library",
                    name: "Fremont Library",
                    description: "Part of Alameda County Library system",
                    phone: "(510) 745-1400",
                    website: "https://aclibrary.org/locations/fre/",
                    iconName: "books.vertical.fill",
                    colorHex: "#5D4037"
                ),
                CityAgency(
                    id: "parks-rec",
                    name: "Community Services",
                    description: "Parks, recreation, and community programs",
                    phone: "(510) 494-4300",
                    website: "https://www.fremont.gov/government/departments/community-services",
                    iconName: "leaf.fill",
                    colorHex: "#388E3C"
                ),
            ],
            cityWebsite: "https://www.fremont.gov/"
        ),
    ]
}
