import Foundation

/// Service for matching queries against pre-written quick answers
/// This provides fast, cached responses for common queries without hitting the AI API
public actor QuickAnswersService {
    public static let shared = QuickAnswersService()

    private var quickAnswers: QuickAnswersData?
    private var isLoaded = false

    private init() {}

    // MARK: - Loading

    /// Load quick answers from bundled JSON
    public func loadIfNeeded() async {
        guard !isLoaded else { return }

        guard let url = Bundle.module.url(forResource: "quick-answers", withExtension: "json") else {
            print("[QuickAnswers] Could not find quick-answers.json in bundle")
            isLoaded = true
            return
        }

        do {
            let data = try Data(contentsOf: url)
            quickAnswers = try JSONDecoder().decode(QuickAnswersData.self, from: data)
            isLoaded = true
            print("[QuickAnswers] Loaded quick answers successfully")
        } catch {
            print("[QuickAnswers] Failed to load quick answers: \(error)")
            isLoaded = true
        }
    }

    // MARK: - Crisis Detection

    /// Check if query matches a crisis pattern
    public func matchCrisis(_ query: String) async -> QuickAnswerResponse? {
        await loadIfNeeded()
        guard let data = quickAnswers else { return nil }

        let lowerQuery = query.lowercased()

        for pattern in data.crisisPatterns {
            for keyword in pattern.patterns {
                if lowerQuery.contains(keyword.lowercased()) {
                    return pattern.response
                }
            }
        }

        return nil
    }

    // MARK: - Clarification Detection

    /// Check if query needs clarification (too vague)
    public func matchClarify(_ query: String) async -> QuickAnswerResponse? {
        await loadIfNeeded()
        guard let data = quickAnswers else { return nil }

        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Only match if query is very short/vague
        guard lowerQuery.split(separator: " ").count <= 4 else { return nil }

        for pattern in data.clarifyPatterns {
            for keyword in pattern.patterns {
                if lowerQuery == keyword.lowercased() || lowerQuery.hasPrefix(keyword.lowercased() + " ") {
                    return pattern.response
                }
            }
        }

        return nil
    }

    // MARK: - Category Intent Matching

    /// Match query to a category intent for quick response
    public func matchCategoryIntent(_ query: String) async -> QuickAnswerResponse? {
        await loadIfNeeded()
        guard let data = quickAnswers else { return nil }

        let lowerQuery = query.lowercased()

        for pattern in data.categoryIntentPatterns {
            for keyword in pattern.patterns {
                if lowerQuery.contains(keyword.lowercased()) {
                    return pattern.response
                }
            }
        }

        return nil
    }

    // MARK: - Program Info Matching

    /// Match query asking about a specific program
    public func matchProgramQuery(_ query: String) async -> QuickAnswerResponse? {
        await loadIfNeeded()
        guard let data = quickAnswers else { return nil }

        let lowerQuery = query.lowercased()

        for pattern in data.programQueries {
            for keyword in pattern.patterns {
                if lowerQuery.contains(keyword.lowercased()) {
                    return pattern.response
                }
            }
        }

        return nil
    }

    // MARK: - Eligibility Query Matching

    /// Match eligibility questions
    public func matchEligibilityQuery(_ query: String) async -> (title: String, url: String)? {
        await loadIfNeeded()
        guard let data = quickAnswers else { return nil }

        let lowerQuery = query.lowercased()

        // Check if query contains eligibility triggers
        let hasEligibilityTrigger = data.eligibilityQueries.triggers.contains { trigger in
            lowerQuery.contains(trigger.lowercased())
        }

        guard hasEligibilityTrigger else { return nil }

        // Find matching program
        for (_, program) in data.eligibilityQueries.programs {
            for keyword in program.keywords {
                if lowerQuery.contains(keyword.lowercased()) {
                    return (title: program.title, url: program.url)
                }
            }
        }

        return nil
    }

    // MARK: - County Contact

    /// Get county contact info from city name
    public func getCountyContact(for city: String) async -> CountyContactInfo? {
        await loadIfNeeded()
        guard let data = quickAnswers else { return nil }

        let lowerCity = city.lowercased()

        guard let countyKey = data.cityToCounty[lowerCity],
              let contact = data.countyContacts[countyKey] else {
            return nil
        }

        return contact
    }

    // MARK: - Full Query Matching

    /// Try to match a query against all quick answer patterns
    /// Returns nil if no match found (should fall back to AI)
    public func matchQuery(_ query: String) async -> QuickAnswerResult? {
        await loadIfNeeded()

        // Priority 1: Crisis detection (immediate response needed)
        if let crisis = await matchCrisis(query) {
            return QuickAnswerResult(
                type: .crisis,
                response: crisis,
                shouldContinueToAI: false
            )
        }

        // Priority 2: Clarification needed
        if let clarify = await matchClarify(query) {
            return QuickAnswerResult(
                type: .clarify,
                response: clarify,
                shouldContinueToAI: false
            )
        }

        // Priority 3: Specific program info
        if let program = await matchProgramQuery(query) {
            return QuickAnswerResult(
                type: .program,
                response: program,
                shouldContinueToAI: false
            )
        }

        // Priority 4: Category intent
        if let category = await matchCategoryIntent(query) {
            return QuickAnswerResult(
                type: .category,
                response: category,
                shouldContinueToAI: true  // Can enhance with AI if available
            )
        }

        // No match - should use AI
        return nil
    }
}

// MARK: - Result Types

public struct QuickAnswerResult: Sendable {
    public enum AnswerType: Sendable {
        case crisis
        case clarify
        case program
        case category
    }

    public let type: AnswerType
    public let response: QuickAnswerResponse
    public let shouldContinueToAI: Bool
}

// MARK: - Data Models

struct QuickAnswersData: Codable {
    let version: String
    let lastUpdated: String
    let description: String
    let countyContacts: [String: CountyContactInfo]
    let cityToCounty: [String: String]
    let clarifyPatterns: [QuickAnswerPattern]
    let crisisPatterns: [QuickAnswerPattern]
    let categoryIntentPatterns: [QuickAnswerPattern]
    let programQueries: [QuickAnswerPattern]
    let eligibilityQueries: EligibilityQueries
    let fallback: FallbackInfo
}

struct QuickAnswerPattern: Codable {
    let patterns: [String]
    let response: QuickAnswerResponse
}

public struct QuickAnswerResponse: Codable, Sendable {
    public let type: String
    public let title: String?
    public let message: String?
    public let summary: String?
    public let resource: QuickAnswerResourceInfo?
    public let secondary: QuickAnswerResourceInfo?
    public let categories: [QuickAnswerCategoryInfo]?
    public let guideUrl: String?
    public let guideText: String?
    public let applyUrl: String?
    public let applyText: String?
    public let search: String?
    public let programId: String?

    public var isCrisis: Bool { type == "crisis" }
    public var needsClarification: Bool { type == "clarify" }
}

public struct QuickAnswerResourceInfo: Codable, Sendable {
    public let name: String
    public let phone: String?
    public let description: String?
    public let action: String?
}

public struct QuickAnswerCategoryInfo: Codable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let icon: String?
    public let search: String?
}

public struct CountyContactInfo: Codable, Sendable {
    public let name: String
    public let phone: String
    public let agency: String
}

struct EligibilityQueries: Codable {
    let triggers: [String]
    let programs: [String: EligibilityProgram]
}

struct EligibilityProgram: Codable {
    let keywords: [String]
    let url: String
    let title: String
}

struct FallbackInfo: Codable {
    let message: String
    let resource: QuickAnswerResourceInfo
}
