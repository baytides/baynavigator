import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Service for persisting window state (size, position) on macOS
/// Allows the app to remember window configuration between launches
public final class WindowStateService: Sendable {
    public static let shared = WindowStateService()

    // MARK: - User Defaults Keys

    private let windowStateKey = "baynavigator:window_state"

    // MARK: - Default Values

    /// Default window size for new installations
    public static let defaultSize = CGSize(width: 1200, height: 800)

    /// Minimum window size
    public static let minimumSize = CGSize(width: 800, height: 600)

    private init() {}

    // MARK: - Platform Detection

    /// Check if we're on a desktop platform that supports window state
    public var isDesktopPlatform: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    // MARK: - State Management

    /// Save window state to UserDefaults
    /// - Parameters:
    ///   - frame: The window frame (position and size)
    ///   - isFullScreen: Whether the window is in full screen mode
    public func saveWindowState(frame: CGRect, isFullScreen: Bool = false) {
        guard isDesktopPlatform else { return }

        let state: [String: Any] = [
            "width": frame.width,
            "height": frame.height,
            "x": frame.origin.x,
            "y": frame.origin.y,
            "isFullScreen": isFullScreen,
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]

        if let data = try? JSONSerialization.data(withJSONObject: state) {
            UserDefaults.standard.set(data, forKey: windowStateKey)
        }
    }

    /// Load saved window state from UserDefaults
    /// - Returns: The saved window state, or nil if none exists
    public func loadWindowState() -> WindowState? {
        guard isDesktopPlatform else { return nil }

        guard let data = UserDefaults.standard.data(forKey: windowStateKey),
              let state = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let width = state["width"] as? CGFloat,
              let height = state["height"] as? CGFloat,
              let x = state["x"] as? CGFloat,
              let y = state["y"] as? CGFloat else {
            return nil
        }

        let isFullScreen = state["isFullScreen"] as? Bool ?? false

        return WindowState(
            width: width,
            height: height,
            x: x,
            y: y,
            isFullScreen: isFullScreen
        )
    }

    /// Clear saved window state
    public func clearWindowState() {
        UserDefaults.standard.removeObject(forKey: windowStateKey)
    }

    /// Get the default window frame for new installations
    /// Centers the window on the main screen
    public func defaultWindowFrame() -> CGRect {
        #if os(macOS)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (Self.defaultSize.width / 2)
            let y = screenFrame.midY - (Self.defaultSize.height / 2)
            return CGRect(
                x: x,
                y: y,
                width: Self.defaultSize.width,
                height: Self.defaultSize.height
            )
        }
        #endif

        return CGRect(
            x: 100,
            y: 100,
            width: Self.defaultSize.width,
            height: Self.defaultSize.height
        )
    }

    /// Validate and adjust window frame to ensure it's visible on screen
    /// - Parameter frame: The frame to validate
    /// - Returns: An adjusted frame that fits within visible screen bounds
    public func validateWindowFrame(_ frame: CGRect) -> CGRect {
        var adjustedFrame = frame

        // Ensure minimum size
        if adjustedFrame.width < Self.minimumSize.width {
            adjustedFrame.size.width = Self.minimumSize.width
        }
        if adjustedFrame.height < Self.minimumSize.height {
            adjustedFrame.size.height = Self.minimumSize.height
        }

        #if os(macOS)
        // Ensure window is on a visible screen
        let screens = NSScreen.screens
        var isOnScreen = false

        for screen in screens {
            let visibleFrame = screen.visibleFrame
            // Check if at least part of the title bar is visible
            let titleBarArea = CGRect(
                x: adjustedFrame.minX,
                y: adjustedFrame.maxY - 30,
                width: adjustedFrame.width,
                height: 30
            )
            if visibleFrame.intersects(titleBarArea) {
                isOnScreen = true
                break
            }
        }

        // If window is completely off-screen, reset to default position
        if !isOnScreen {
            return defaultWindowFrame()
        }
        #endif

        return adjustedFrame
    }
}

// MARK: - Window State Model

/// Represents saved window state
public struct WindowState: Codable, Sendable {
    public let width: CGFloat
    public let height: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    public let isFullScreen: Bool

    public init(
        width: CGFloat,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat,
        isFullScreen: Bool = false
    ) {
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.isFullScreen = isFullScreen
    }

    /// Get as CGSize
    public var size: CGSize {
        CGSize(width: width, height: height)
    }

    /// Get as CGPoint
    public var position: CGPoint {
        CGPoint(x: x, y: y)
    }

    /// Get as CGRect
    public var frame: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - macOS Window Controller Extension

#if os(macOS)
import SwiftUI

/// SwiftUI Scene modifier for window state persistence
public struct WindowStatePersistence: ViewModifier {
    @State private var hasRestoredState = false

    public init() {}

    public func body(content: Content) -> some View {
        content
            .onAppear {
                restoreWindowState()
            }
            .onDisappear {
                saveWindowState()
            }
    }

    private func restoreWindowState() {
        guard !hasRestoredState else { return }
        hasRestoredState = true

        if let savedState = WindowStateService.shared.loadWindowState() {
            let validatedFrame = WindowStateService.shared.validateWindowFrame(savedState.frame)

            // Apply to key window
            DispatchQueue.main.async {
                if let window = NSApplication.shared.keyWindow {
                    window.setFrame(validatedFrame, display: true, animate: false)

                    if savedState.isFullScreen && !window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
            }
        }
    }

    private func saveWindowState() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.keyWindow {
                let isFullScreen = window.styleMask.contains(.fullScreen)
                WindowStateService.shared.saveWindowState(
                    frame: window.frame,
                    isFullScreen: isFullScreen
                )
            }
        }
    }
}

public extension View {
    /// Apply window state persistence to a view
    func persistWindowState() -> some View {
        modifier(WindowStatePersistence())
    }
}

/// Window delegate for automatic state saving
public class WindowStateDelegate: NSObject, NSWindowDelegate {
    public static let shared = WindowStateDelegate()

    public func windowDidResize(_ notification: Notification) {
        saveCurrentWindowState(notification)
    }

    public func windowDidMove(_ notification: Notification) {
        saveCurrentWindowState(notification)
    }

    public func windowWillClose(_ notification: Notification) {
        saveCurrentWindowState(notification)
    }

    public func windowDidExitFullScreen(_ notification: Notification) {
        saveCurrentWindowState(notification)
    }

    public func windowDidEnterFullScreen(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            WindowStateService.shared.saveWindowState(
                frame: window.frame,
                isFullScreen: true
            )
        }
    }

    private func saveCurrentWindowState(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            let isFullScreen = window.styleMask.contains(.fullScreen)
            WindowStateService.shared.saveWindowState(
                frame: window.frame,
                isFullScreen: isFullScreen
            )
        }
    }
}
#endif

// MARK: - Preview

#if DEBUG
#Preview("Window State Service") {
    VStack(spacing: 20) {
        Text("Window State Service")
            .font(.headline)

        Text("Platform: \(WindowStateService.shared.isDesktopPlatform ? "Desktop" : "Mobile")")

        if let state = WindowStateService.shared.loadWindowState() {
            VStack(alignment: .leading) {
                Text("Saved State:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Size: \(Int(state.width)) x \(Int(state.height))")
                Text("Position: (\(Int(state.x)), \(Int(state.y)))")
                Text("Full Screen: \(state.isFullScreen ? "Yes" : "No")")
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        } else {
            Text("No saved window state")
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
#endif
