import SwiftUI

// MARK: - WCAG 2.2 AAA Accessibility Extensions for Bay Navigator visionOS
//
// This file provides accessibility utilities matching the web app's WCAG 2.2 AAA
// + WCAG 3.0 draft compliance, including:
// - Accessibility labels and hints for all interactive elements
// - Reduce motion support
// - High contrast mode support
// - Dynamic Type support
// - VoiceOver announcements
// - Semantic group labels

// MARK: - Accessibility Environment Values

struct AccessibilityReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Access reduce motion preference from environment
    var prefersReducedMotion: Bool {
        get { self[AccessibilityReduceMotionKey.self] }
        set { self[AccessibilityReduceMotionKey.self] = newValue }
    }
}

// MARK: - Semantic Labels

/// Centralized accessibility labels matching web app standards
enum AccessibilityLabels {
    // Navigation
    static let home = "Home"
    static let directory = "Program Directory"
    static let saved = "Saved Programs"
    static let settings = "Settings"
    static let search = "Search programs"
    static let filter = "Filter programs"
    static let sort = "Sort programs"
    static let smartAssistant = "Smart Assistant - Ask questions about benefits"

    // Actions
    static func saveProgram(_ name: String) -> String {
        "Save \(name) to your list"
    }

    static func unsaveProgram(_ name: String) -> String {
        "Remove \(name) from your list"
    }

    static func shareProgram(_ name: String) -> String {
        "Share \(name)"
    }

    static func callPhone(_ phone: String) -> String {
        "Call \(phone)"
    }

    static func openWebsite(_ name: String) -> String {
        "Open \(name) website"
    }

    static func getDirections(_ location: String) -> String {
        "Get directions to \(location)"
    }

    // States
    static func programSaved(_ name: String) -> String {
        "\(name) is saved"
    }

    static func programNotSaved(_ name: String) -> String {
        "\(name) is not saved"
    }

    static func filterActive(_ count: Int) -> String {
        "\(count) filter\(count == 1 ? "" : "s") active"
    }

    static func resultsCount(_ count: Int) -> String {
        "\(count) program\(count == 1 ? "" : "s") found"
    }

    static let loadingPrograms = "Loading programs"

    // Categories
    static func categoryLabel(_ category: String) -> String {
        "\(category) programs"
    }

    // Program card
    static func programCard(_ program: String, category: String, location: String) -> String {
        "\(program), \(category) program in \(location)"
    }
}

// MARK: - Group Labels (Accessibility-friendly descriptions)

/// Maps group IDs to human-readable accessibility labels
enum GroupLabels {
    static let labels: [String: String] = [
        "low-income": "Low income individuals and families",
        "seniors": "Seniors 65 and older",
        "youth": "Youth and young adults",
        "college-students": "College students",
        "veterans": "Veterans and military families",
        "families": "Families with children",
        "disability": "People with disabilities",
        "lgbtq": "LGBTQ+ community",
        "first-responders": "First responders",
        "teachers": "Teachers and educators",
        "unemployed": "Unemployed or job seekers",
        "immigrants": "Immigrants and refugees",
        "unhoused": "People experiencing homelessness",
        "pregnant": "Pregnant individuals",
        "caregivers": "Caregivers",
        "foster-youth": "Foster youth",
        "reentry": "People reentering from incarceration",
        "nonprofits": "Nonprofit organizations",
        "everyone": "Everyone - no restrictions"
    ]

    static func label(for group: String) -> String {
        labels[group.lowercased()] ?? group.capitalized
    }
}

// MARK: - Accessibility View Modifiers

/// Modifier to add standard program card accessibility
struct ProgramCardAccessibility: ViewModifier {
    let program: String
    let category: String
    let location: String
    let isFavorite: Bool
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityLabels.programCard(program, category: category, location: location))
            .accessibilityHint(isFavorite ? "Saved. Double tap to view details." : "Double tap to view details.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                onTap()
            }
    }
}

/// Modifier to add favorite button accessibility
struct FavoriteButtonAccessibility: ViewModifier {
    let programName: String
    let isFavorite: Bool
    let onToggle: () -> Void

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(isFavorite
                ? AccessibilityLabels.unsaveProgram(programName)
                : AccessibilityLabels.saveProgram(programName))
            .accessibilityHint(isFavorite
                ? "Double tap to remove from saved programs"
                : "Double tap to save to your list")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                onToggle()
            }
    }
}

/// Modifier to respect reduce motion preference
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let animation: Animation
    let reducedAnimation: Animation

    init(animation: Animation = .easeInOut(duration: 0.3), reducedAnimation: Animation = .linear(duration: 0.01)) {
        self.animation = animation
        self.reducedAnimation = reducedAnimation
    }

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : animation, value: UUID())
    }
}

/// Modifier to add high contrast colors when needed
struct HighContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast

    let normalColor: Color
    let highContrastColor: Color

    func body(content: Content) -> some View {
        content
            .foregroundStyle(contrast == .increased ? highContrastColor : normalColor)
    }
}

// MARK: - View Extensions

extension View {
    /// Add program card accessibility
    func programCardAccessibility(
        program: String,
        category: String,
        location: String,
        isFavorite: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        modifier(ProgramCardAccessibility(
            program: program,
            category: category,
            location: location,
            isFavorite: isFavorite,
            onTap: onTap
        ))
    }

    /// Add favorite button accessibility
    func favoriteButtonAccessibility(
        programName: String,
        isFavorite: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        modifier(FavoriteButtonAccessibility(
            programName: programName,
            isFavorite: isFavorite,
            onToggle: onToggle
        ))
    }

    /// Respect reduce motion preference for animations
    func respectReduceMotion(
        animation: Animation = .easeInOut(duration: 0.3)
    ) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }

    /// Apply high contrast colors when system setting is enabled
    func highContrastForeground(
        normal: Color,
        highContrast: Color
    ) -> some View {
        modifier(HighContrastModifier(normalColor: normal, highContrastColor: highContrast))
    }

    /// Add heading trait for screen readers
    func accessibilityHeading(_ level: AccessibilityHeadingLevel = .h2) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
    }

    /// Mark as decorative (excluded from accessibility)
    func accessibilityDecorative() -> some View {
        self
            .accessibilityHidden(true)
    }

    /// Add live region for dynamic content updates
    func accessibilityLiveRegion() -> some View {
        self
            .accessibilityAddTraits(.updatesFrequently)
    }

    /// Add link trait
    func accessibilityLink(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isLink)
    }
}

// MARK: - Accessible Animation Wrapper

/// Animation wrapper that respects reduce motion preference
struct AccessibleAnimation<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    let content: Content
    let animation: Animation

    init(animation: Animation = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        self.animation = animation
        self.content = content()
    }

    var body: some View {
        content
            .animation(reduceMotion ? nil : animation, value: UUID())
    }
}

// MARK: - Announcement Helper

/// Helper to post VoiceOver announcements
enum AccessibilityAnnouncement {
    /// Announce a message to VoiceOver users
    static func announce(_ message: String) {
        // Use notification center for accessibility announcements
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    /// Announce loading state
    static func announceLoading() {
        announce("Loading")
    }

    /// Announce loading complete
    static func announceLoadingComplete(_ count: Int? = nil) {
        if let count = count {
            announce("Loaded \(count) programs")
        } else {
            announce("Loading complete")
        }
    }

    /// Announce filter change
    static func announceFilterChange(_ resultCount: Int) {
        announce("Showing \(resultCount) results")
    }

    /// Announce save/unsave action
    static func announceSaveAction(isSaved: Bool, programName: String) {
        if isSaved {
            announce("\(programName) saved to your list")
        } else {
            announce("\(programName) removed from your list")
        }
    }

    /// Announce error
    static func announceError(_ error: String) {
        announce("Error: \(error)")
    }

    /// Announce page change
    static func announcePageChange(_ pageName: String) {
        announce("Now viewing \(pageName)")
    }
}

// MARK: - High Contrast Colors

/// High contrast color overrides (10:1+ ratio) matching web standards
enum HighContrastColors {
    static let text = Color.black
    static let textOnDark = Color.white
    static let background = Color.white
    static let backgroundDark = Color.black
    static let primary = Color(red: 0, green: 0.25, blue: 0.25) // Darker teal
    static let primaryOnDark = Color(red: 0.5, green: 1, blue: 1) // Bright cyan
    static let link = Color(red: 0, green: 0, blue: 0.8) // Traditional link blue
    static let linkOnDark = Color(red: 0.6, green: 0.8, blue: 1)
    static let focus = Color.black
    static let focusOnDark = Color.yellow // Yellow focus ring
    static let error = Color(red: 0.8, green: 0, blue: 0)
    static let errorOnDark = Color(red: 1, green: 0.4, blue: 0.4)
    static let success = Color(red: 0, green: 0.4, blue: 0)
    static let successOnDark = Color(red: 0.4, green: 1, blue: 0.4)
}

// MARK: - Category Accessibility Labels

extension String {
    /// Get accessibility label for category
    var categoryAccessibilityLabel: String {
        switch self.lowercased() {
        case "food", "food assistance":
            return "Food assistance programs"
        case "health", "healthcare", "medical":
            return "Healthcare programs"
        case "recreation", "activities", "entertainment":
            return "Recreation and activities"
        case "community", "community services", "social services":
            return "Community services"
        case "education", "learning", "training":
            return "Education and training programs"
        case "finance", "financial", "financial assistance":
            return "Financial assistance programs"
        case "transportation", "transit":
            return "Transportation programs"
        case "technology", "tech", "internet":
            return "Technology resources"
        case "legal", "legal aid":
            return "Legal aid services"
        case "housing", "shelter":
            return "Housing assistance"
        case "employment", "jobs", "career":
            return "Employment and career services"
        case "pet resources", "pets":
            return "Pet resources"
        case "utilities", "energy":
            return "Utility assistance"
        case "childcare", "childcare assistance":
            return "Childcare assistance"
        case "clothing", "clothing assistance":
            return "Clothing assistance"
        case "library resources", "library":
            return "Library resources"
        default:
            return "\(self) programs"
        }
    }
}
