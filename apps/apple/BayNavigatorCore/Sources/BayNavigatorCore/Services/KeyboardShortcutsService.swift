import Foundation
import SwiftUI

/// Global keyboard shortcuts for desktop platforms
/// Provides consistent keyboard navigation and actions
public final class KeyboardShortcutsService: Sendable {
    public static let shared = KeyboardShortcutsService()

    private init() {}

    // MARK: - Platform Detection

    /// Check if we're on a platform that supports keyboard shortcuts
    public var supportsKeyboardShortcuts: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Shortcut Hints

    /// Get shortcut hint text for display (platform-aware)
    /// - Parameter action: The action identifier
    /// - Returns: Human-readable shortcut hint (e.g., "⌘F" or "Ctrl+F")
    public func getShortcutHint(_ action: ShortcutAction) -> String {
        #if os(macOS)
        let cmd = "\u{2318}" // ⌘
        let shift = "\u{21E7}" // ⇧
        let opt = "\u{2325}" // ⌥
        #else
        let cmd = "Ctrl+"
        let shift = "Shift+"
        let opt = "Alt+"
        #endif

        switch action {
        case .search:
            return "\(cmd)F"
        case .settings:
            return "\(cmd),"
        case .filters:
            return "\(cmd)L"
        case .refresh:
            return "\(cmd)R"
        case .export:
            return "\(cmd)\(shift)E"
        case .print:
            return "\(cmd)P"
        case .toggleTheme:
            return "\(cmd)\(shift)D"
        case .goToHome:
            return "\(cmd)1"
        case .goToSaved:
            return "\(cmd)2"
        case .goToMore:
            return "\(cmd)3"
        case .escape:
            return "Esc"
        case .newWindow:
            return "\(cmd)N"
        case .closeWindow:
            return "\(cmd)W"
        case .minimize:
            return "\(cmd)M"
        case .fullScreen:
            return "\(cmd)\(opt)F"
        case .zoomIn:
            return "\(cmd)+"
        case .zoomOut:
            return "\(cmd)-"
        case .resetZoom:
            return "\(cmd)0"
        case .help:
            return "\(cmd)?"
        case .quickExit:
            return "\(cmd)Q"
        }
    }

    /// Get all available shortcuts grouped by category
    public var allShortcuts: [ShortcutCategory: [ShortcutInfo]] {
        [
            .navigation: [
                ShortcutInfo(action: .search, title: "Focus Search", hint: getShortcutHint(.search)),
                ShortcutInfo(action: .goToHome, title: "Go to Home", hint: getShortcutHint(.goToHome)),
                ShortcutInfo(action: .goToSaved, title: "Go to Saved", hint: getShortcutHint(.goToSaved)),
                ShortcutInfo(action: .goToMore, title: "Go to More", hint: getShortcutHint(.goToMore)),
                ShortcutInfo(action: .filters, title: "Open Filters", hint: getShortcutHint(.filters)),
                ShortcutInfo(action: .settings, title: "Open Settings", hint: getShortcutHint(.settings))
            ],
            .actions: [
                ShortcutInfo(action: .refresh, title: "Refresh", hint: getShortcutHint(.refresh)),
                ShortcutInfo(action: .export, title: "Export", hint: getShortcutHint(.export)),
                ShortcutInfo(action: .print, title: "Print", hint: getShortcutHint(.print)),
                ShortcutInfo(action: .toggleTheme, title: "Toggle Theme", hint: getShortcutHint(.toggleTheme))
            ],
            .window: [
                ShortcutInfo(action: .newWindow, title: "New Window", hint: getShortcutHint(.newWindow)),
                ShortcutInfo(action: .closeWindow, title: "Close Window", hint: getShortcutHint(.closeWindow)),
                ShortcutInfo(action: .minimize, title: "Minimize", hint: getShortcutHint(.minimize)),
                ShortcutInfo(action: .fullScreen, title: "Full Screen", hint: getShortcutHint(.fullScreen))
            ],
            .view: [
                ShortcutInfo(action: .zoomIn, title: "Zoom In", hint: getShortcutHint(.zoomIn)),
                ShortcutInfo(action: .zoomOut, title: "Zoom Out", hint: getShortcutHint(.zoomOut)),
                ShortcutInfo(action: .resetZoom, title: "Reset Zoom", hint: getShortcutHint(.resetZoom))
            ],
            .other: [
                ShortcutInfo(action: .escape, title: "Dismiss / Cancel", hint: getShortcutHint(.escape)),
                ShortcutInfo(action: .help, title: "Help", hint: getShortcutHint(.help)),
                ShortcutInfo(action: .quickExit, title: "Quick Exit", hint: getShortcutHint(.quickExit))
            ]
        ]
    }
}

// MARK: - Data Models

/// Keyboard shortcut action identifiers
public enum ShortcutAction: String, CaseIterable, Sendable {
    // Navigation
    case search
    case settings
    case filters
    case goToHome
    case goToSaved
    case goToMore

    // Actions
    case refresh
    case export
    case print
    case toggleTheme

    // Window
    case newWindow
    case closeWindow
    case minimize
    case fullScreen

    // View
    case zoomIn
    case zoomOut
    case resetZoom

    // Other
    case escape
    case help
    case quickExit
}

/// Shortcut category for grouping
public enum ShortcutCategory: String, CaseIterable, Sendable {
    case navigation = "Navigation"
    case actions = "Actions"
    case window = "Window"
    case view = "View"
    case other = "Other"
}

/// Shortcut information for display
public struct ShortcutInfo: Identifiable, Sendable {
    public let id = UUID()
    public let action: ShortcutAction
    public let title: String
    public let hint: String

    public init(action: ShortcutAction, title: String, hint: String) {
        self.action = action
        self.title = title
        self.hint = hint
    }
}

// MARK: - SwiftUI Keyboard Shortcut Extensions

#if os(macOS)
public extension View {
    /// Add common keyboard shortcuts to a view
    /// - Parameters:
    ///   - onSearch: Handler for search shortcut (⌘F)
    ///   - onSettings: Handler for settings shortcut (⌘,)
    ///   - onRefresh: Handler for refresh shortcut (⌘R)
    ///   - onEscape: Handler for escape shortcut
    func withKeyboardShortcuts(
        onSearch: (() -> Void)? = nil,
        onSettings: (() -> Void)? = nil,
        onRefresh: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        self
            .keyboardShortcut("f", modifiers: .command)
            .onKeyPress(.escape) {
                onEscape?()
                return onEscape != nil ? .handled : .ignored
            }
    }

    /// Add search focus keyboard shortcut
    func searchShortcut(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut("f", modifiers: .command)
    }

    /// Add refresh keyboard shortcut
    func refreshShortcut(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut("r", modifiers: .command)
    }

    /// Add export keyboard shortcut
    func exportShortcut(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut("e", modifiers: [.command, .shift])
    }

    /// Add print keyboard shortcut
    func printShortcut(action: @escaping () -> Void) -> some View {
        self.keyboardShortcut("p", modifiers: .command)
    }
}

/// Keyboard shortcut handler for the main app window
public struct KeyboardShortcutHandler: ViewModifier {
    let onSearch: () -> Void
    let onSettings: () -> Void
    let onRefresh: () -> Void
    let onFilters: () -> Void
    let onExport: () -> Void
    let onPrint: () -> Void
    let onToggleTheme: () -> Void
    let onGoToTab: (Int) -> Void
    let onEscape: () -> Void

    public init(
        onSearch: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onRefresh: @escaping () -> Void,
        onFilters: @escaping () -> Void,
        onExport: @escaping () -> Void,
        onPrint: @escaping () -> Void,
        onToggleTheme: @escaping () -> Void,
        onGoToTab: @escaping (Int) -> Void,
        onEscape: @escaping () -> Void
    ) {
        self.onSearch = onSearch
        self.onSettings = onSettings
        self.onRefresh = onRefresh
        self.onFilters = onFilters
        self.onExport = onExport
        self.onPrint = onPrint
        self.onToggleTheme = onToggleTheme
        self.onGoToTab = onGoToTab
        self.onEscape = onEscape
    }

    public func body(content: Content) -> some View {
        content
            .onKeyPress(.escape) {
                onEscape()
                return .handled
            }
            // Note: Most shortcuts are handled via Commands in the App definition
            // This modifier handles view-specific shortcuts
    }
}

public extension View {
    /// Apply the full keyboard shortcut handler
    func handleKeyboardShortcuts(
        onSearch: @escaping () -> Void = {},
        onSettings: @escaping () -> Void = {},
        onRefresh: @escaping () -> Void = {},
        onFilters: @escaping () -> Void = {},
        onExport: @escaping () -> Void = {},
        onPrint: @escaping () -> Void = {},
        onToggleTheme: @escaping () -> Void = {},
        onGoToTab: @escaping (Int) -> Void = { _ in },
        onEscape: @escaping () -> Void = {}
    ) -> some View {
        modifier(KeyboardShortcutHandler(
            onSearch: onSearch,
            onSettings: onSettings,
            onRefresh: onRefresh,
            onFilters: onFilters,
            onExport: onExport,
            onPrint: onPrint,
            onToggleTheme: onToggleTheme,
            onGoToTab: onGoToTab,
            onEscape: onEscape
        ))
    }
}
#endif

// MARK: - SwiftUI Shortcut Help View

/// A view that displays available keyboard shortcuts
public struct KeyboardShortcutsHelpView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                ForEach(ShortcutCategory.allCases, id: \.self) { category in
                    if let shortcuts = KeyboardShortcutsService.shared.allShortcuts[category] {
                        Section(category.rawValue) {
                            ForEach(shortcuts) { shortcut in
                                HStack {
                                    Text(shortcut.title)
                                    Spacer()
                                    Text(shortcut.hint)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            #if os(macOS)
            .frame(minWidth: 400, minHeight: 500)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Keyboard Shortcuts Help") {
    KeyboardShortcutsHelpView()
}
#endif
