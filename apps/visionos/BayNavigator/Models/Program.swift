import Foundation

struct Program: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let description: String
    let fullDescription: String?
    let whatTheyOffer: String?
    let howToGetIt: String?
    let groups: [String]
    let areas: [String]
    let city: String?
    let website: String?
    let cost: String?
    let phone: String?
    let email: String?
    let address: String?
    let requirements: String?
    let howToApply: String?
    let lastUpdated: String
    let latitude: Double?
    let longitude: Double?

    // Calculated at runtime (not persisted)
    var distanceFromUser: Double?

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    // Custom Hashable conformance (exclude distanceFromUser)
    static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Custom Codable keys (exclude distanceFromUser from JSON)
    enum CodingKeys: String, CodingKey {
        case id, name, category, description, fullDescription
        case whatTheyOffer, howToGetIt, groups, areas, city
        case website, cost, phone, email, address
        case requirements, howToApply, lastUpdated
        case latitude, longitude
    }

    var lastUpdatedDate: Date? {
        // Try simple date format first (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: lastUpdated) {
            return date
        }
        // Fallback to ISO8601
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: lastUpdated) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: lastUpdated)
    }

    var formattedLastUpdated: String {
        guard let date = lastUpdatedDate else { return lastUpdated }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Get display description (prefer fullDescription, fallback to description)
    var displayDescription: String {
        fullDescription ?? description
    }

    /// Get location text for display
    var locationText: String {
        if let city = city, !city.isEmpty { return city }
        if !areas.isEmpty { return areas.joined(separator: ", ") }
        return "Bay Area"
    }

    /// Parse whatTheyOffer into list items
    var offerItems: [String] {
        guard let text = whatTheyOffer, !text.isEmpty else { return [] }
        return text
            .components(separatedBy: "\n")
            .map { line in
                var cleaned = line
                if cleaned.hasPrefix("- ") {
                    cleaned = String(cleaned.dropFirst(2))
                }
                return cleaned.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }

    /// Parse howToGetIt into numbered steps
    var howToSteps: [String] {
        guard let text = howToGetIt, !text.isEmpty else { return [] }
        return text
            .components(separatedBy: "\n")
            .map { line in
                var cleaned = line.trimmingCharacters(in: .whitespaces)
                // Remove leading number and period (e.g., "1. ", "2. ")
                if let range = cleaned.range(of: #"^\d+\.\s*"#, options: .regularExpression) {
                    cleaned = String(cleaned[range.upperBound...])
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
    }
}

struct ProgramsResponse: Codable {
    let programs: [Program]
}

struct ProgramCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let programCount: Int
}

struct CategoriesResponse: Codable {
    let categories: [ProgramCategory]
}

struct ProgramGroup: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let programCount: Int
}

struct GroupsResponse: Codable {
    let groups: [ProgramGroup]
}

struct Area: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String // 'county' | 'region' | 'state' | 'nationwide'
    let programCount: Int

    var isCounty: Bool {
        type == "county"
    }
}

struct AreasResponse: Codable {
    let areas: [Area]
}

struct APIMetadata: Codable {
    let version: String
    let generatedAt: String
    let totalPrograms: Int

    var generatedAtDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: generatedAt) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: generatedAt)
    }

    var formattedGeneratedAt: String {
        guard let date = generatedAtDate else { return generatedAt }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FilterState: Equatable {
    var categories: Set<String> = []
    var groups: Set<String> = []
    var areas: Set<String> = []
    var searchQuery: String = ""

    // IDs for "Other" area group (Bay Area, Statewide, Nationwide)
    static let otherAreaIds: Set<String> = ["bay-area", "statewide", "nationwide"]

    var hasFilters: Bool {
        !categories.isEmpty || !groups.isEmpty || !areas.isEmpty || !searchQuery.isEmpty
    }

    var filterCount: Int {
        // Count counties as individual filters, but "Other" (bay-area, statewide, nationwide) as 1
        let countyCount = areas.filter { !Self.otherAreaIds.contains($0) }.count
        let hasOther = areas.contains { Self.otherAreaIds.contains($0) }
        let areaCount = countyCount + (hasOther ? 1 : 0)

        return categories.count + groups.count + areaCount + (searchQuery.isEmpty ? 0 : 1)
    }

    var selectedAreaDisplayCount: Int {
        let countyCount = areas.filter { !Self.otherAreaIds.contains($0) }.count
        let hasOther = areas.contains { Self.otherAreaIds.contains($0) }
        return countyCount + (hasOther ? 1 : 0)
    }

    var hasOtherAreasSelected: Bool {
        areas.contains { Self.otherAreaIds.contains($0) }
    }

    mutating func clear() {
        categories.removeAll()
        groups.removeAll()
        areas.removeAll()
        searchQuery = ""
    }

    mutating func toggleOtherAreas() {
        if hasOtherAreasSelected {
            // Remove all "other" area IDs
            areas.subtract(Self.otherAreaIds)
        } else {
            // Add all "other" area IDs
            areas.formUnion(Self.otherAreaIds)
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case recentlyVerified = "Recently Verified"
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case categoryAsc = "Category"
    case distanceAsc = "Distance (Nearest)"

    var id: String { rawValue }
}

// MARK: - Favorite Status Tracking

/// Status options for tracking application progress
enum FavoriteStatus: String, Codable, CaseIterable, Identifiable {
    case saved
    case researching
    case applied
    case waiting
    case approved
    case denied

    var id: String { rawValue }

    var label: String {
        switch self {
        case .saved: return "Saved"
        case .researching: return "Researching"
        case .applied: return "Applied"
        case .waiting: return "Waiting for Response"
        case .approved: return "Approved"
        case .denied: return "Denied"
        }
    }

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .saved: return (0.62, 0.62, 0.62)       // Grey
        case .researching: return (0.13, 0.59, 0.95) // Blue
        case .applied: return (1.0, 0.76, 0.03)      // Amber
        case .waiting: return (0.61, 0.15, 0.69)     // Purple
        case .approved: return (0.30, 0.69, 0.31)    // Green
        case .denied: return (0.96, 0.26, 0.21)      // Red
        }
    }

    var systemImage: String {
        switch self {
        case .saved: return "bookmark"
        case .researching: return "magnifyingglass"
        case .applied: return "paperplane"
        case .waiting: return "clock"
        case .approved: return "checkmark.circle"
        case .denied: return "xmark.circle"
        }
    }
}

/// Extended favorite info with status tracking and notes
struct FavoriteItem: Codable, Identifiable {
    let programId: String
    let savedAt: Date
    var status: FavoriteStatus
    var notes: String?
    var statusUpdatedAt: Date?

    var id: String { programId }

    init(programId: String, savedAt: Date = Date(), status: FavoriteStatus = .saved, notes: String? = nil, statusUpdatedAt: Date? = nil) {
        self.programId = programId
        self.savedAt = savedAt
        self.status = status
        self.notes = notes
        self.statusUpdatedAt = statusUpdatedAt
    }

    var hasNotes: Bool {
        guard let notes = notes else { return false }
        return !notes.isEmpty
    }
}
