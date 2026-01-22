import Foundation
import SwiftUI

/// Service for providing category-specific safety tips
/// Helps vulnerable users understand how to safely access sensitive services
public final class SafetyTipsService: Sendable {
    public static let shared = SafetyTipsService()

    // MARK: - User Defaults Keys

    private let showSafetyTipsKey = "baynavigator:show_safety_tips"

    // MARK: - Sensitive Categories

    /// Program categories that should show safety tips
    public static let sensitiveCategories: Set<String> = [
        "crisis",
        "domestic-violence",
        "mental-health",
        "lgbtq",
        "teen-health",
        "substance-abuse",
        "housing-emergency"
    ]

    /// Sensitive eligibility groups
    public static let sensitiveEligibilities: Set<String> = [
        "survivors",
        "lgbtq",
        "youth",
        "immigrants",
        "unhoused",
        "reentry"
    ]

    private init() {}

    // MARK: - Settings

    /// Check if safety tips should be shown
    public var shouldShowSafetyTips: Bool {
        // Default to true for new users
        if UserDefaults.standard.object(forKey: showSafetyTipsKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: showSafetyTipsKey)
    }

    /// Enable or disable safety tips
    public func setShowSafetyTips(_ show: Bool) {
        UserDefaults.standard.set(show, forKey: showSafetyTipsKey)
    }

    // MARK: - Sensitivity Detection

    /// Check if a program is sensitive and should show safety tips
    public func isProgramSensitive(category: String?, eligibility: [String]?) -> Bool {
        if let category = category?.lowercased(),
           Self.sensitiveCategories.contains(category) {
            return true
        }

        if let eligibility = eligibility {
            for group in eligibility {
                if Self.sensitiveEligibilities.contains(group.lowercased()) {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Safety Tips Generation

    /// Get safety tips for a sensitive program
    public func getSafetyTips(category: String?, eligibility: [String]? = nil) -> [SafetyTip] {
        var tips: [SafetyTip] = []
        let lowerCategory = category?.lowercased() ?? ""
        let lowerEligibility = Set(eligibility?.map { $0.lowercased() } ?? [])

        // Universal tips for all sensitive programs
        tips.append(contentsOf: [
            SafetyTip(
                icon: "shield.fill",
                title: "Check your surroundings",
                description: "Make sure you're in a private, safe location before making calls."
            ),
            SafetyTip(
                icon: "clock.arrow.circlepath",
                title: "Clear your history",
                description: "Use Incognito Mode or clear your browser/app history after visiting."
            )
        ])

        // Domestic violence / survivors - most comprehensive tips
        if lowerCategory == "domestic-violence" ||
           lowerCategory == "crisis" ||
           lowerEligibility.contains("survivors") {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "phone.badge.checkmark",
                    title: "Use *67 to hide your number",
                    description: "Dial *67 before the number to block your caller ID from appearing."
                ),
                SafetyTip(
                    icon: "iphone.slash",
                    title: "Consider using a different phone",
                    description: "If your phone is monitored, use a friend's phone, library, or public phone."
                ),
                SafetyTip(
                    icon: "calendar.badge.clock",
                    title: "Plan your call time",
                    description: "Choose a time when you know you'll have privacy and won't be interrupted."
                ),
                SafetyTip(
                    icon: "location.slash.fill",
                    title: "Check location sharing",
                    description: "Review if your location is being shared via Find My, Google Maps, or family apps."
                ),
                SafetyTip(
                    icon: "laptopcomputer.and.iphone",
                    title: "Be aware of shared devices",
                    description: "Browsing history, iCloud, and Google accounts may sync across devices."
                )
            ])
        }

        // LGBTQ+ specific tips
        if lowerCategory == "lgbtq" || lowerEligibility.contains("lgbtq") {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "phone.fill.arrow.up.right",
                    title: "Use a private number",
                    description: "Consider Google Voice, TextNow, or another app for a separate phone number."
                ),
                SafetyTip(
                    icon: "person.3.fill",
                    title: "Check shared accounts",
                    description: "Family plans and shared accounts may show call/text logs to others."
                ),
                SafetyTip(
                    icon: "app.badge.fill",
                    title: "Use app disguise",
                    description: "This app can be disguised as a calculator or notes app in Settings."
                )
            ])
        }

        // Youth / Teen specific tips
        if lowerCategory == "teen-health" || lowerEligibility.contains("youth") {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "text.bubble.fill",
                    title: "Text option available",
                    description: "Many hotlines offer text support if you can't talk safely."
                ),
                SafetyTip(
                    icon: "graduationcap.fill",
                    title: "Talk to a trusted adult",
                    description: "School counselors, coaches, or relatives may be able to help."
                ),
                SafetyTip(
                    icon: "person.crop.circle.badge.exclamationmark",
                    title: "Parental controls",
                    description: "Be aware if your device has monitoring or screen time apps installed."
                )
            ])
        }

        // Mental health specific tips
        if lowerCategory == "mental-health" || lowerCategory == "substance-abuse" {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "message.fill",
                    title: "Text support available",
                    description: "Text HOME to 741741 (Crisis Text Line) if you can't make a call."
                ),
                SafetyTip(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat options",
                    description: "Many services offer online chat that may be less visible than phone calls."
                ),
                SafetyTip(
                    icon: "heart.fill",
                    title: "Warm handoffs available",
                    description: "Ask about being transferred directly to local services while on the line."
                )
            ])
        }

        // Immigrant specific tips
        if lowerEligibility.contains("immigrants") {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "scalemass.fill",
                    title: "Know your rights",
                    description: "You have rights regardless of immigration status. Ask about confidentiality."
                ),
                SafetyTip(
                    icon: "globe",
                    title: "Language support",
                    description: "Many services offer interpretation in multiple languages."
                ),
                SafetyTip(
                    icon: "checkmark.shield.fill",
                    title: "Ask about privacy policies",
                    description: "Confirm that services won't share your information with immigration authorities."
                )
            ])
        }

        // Unhoused / Housing emergency
        if lowerCategory == "housing-emergency" || lowerEligibility.contains("unhoused") {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "wifi",
                    title: "Free WiFi locations",
                    description: "Libraries, community centers, and some fast food restaurants offer free WiFi."
                ),
                SafetyTip(
                    icon: "battery.100.bolt",
                    title: "Charge your phone",
                    description: "Libraries and some shelters have charging stations available."
                )
            ])
        }

        // Reentry / Formerly incarcerated
        if lowerEligibility.contains("reentry") {
            tips.append(contentsOf: [
                SafetyTip(
                    icon: "briefcase.fill",
                    title: "Background-friendly employers",
                    description: "Many programs listed work specifically with people with records."
                ),
                SafetyTip(
                    icon: "doc.text.fill",
                    title: "Record expungement",
                    description: "Ask about services that help with clearing or sealing records."
                )
            ])
        }

        return tips
    }
}

// MARK: - Data Models

/// Safety tip for sensitive programs
public struct SafetyTip: Identifiable, Sendable {
    public let id: UUID
    public let icon: String
    public let title: String
    public let description: String

    public init(icon: String, title: String, description: String) {
        self.id = UUID()
        self.icon = icon
        self.title = title
        self.description = description
    }
}

// MARK: - SwiftUI View

/// A view that displays safety tips
public struct SafetyTipsView: View {
    let tips: [SafetyTip]
    let onDismiss: (() -> Void)?

    public init(tips: [SafetyTip], onDismiss: (() -> Void)? = nil) {
        self.tips = tips
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.orange)
                Text("Safety Tips")
                    .font(.headline)
                Spacer()
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(tips) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.icon)
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(tip.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Safety Tips") {
    SafetyTipsView(
        tips: SafetyTipsService.shared.getSafetyTips(
            category: "domestic-violence",
            eligibility: ["survivors"]
        )
    )
    .padding()
}
#endif
