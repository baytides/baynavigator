import SwiftUI
import Lottie

/// A SwiftUI wrapper for Lottie animations with cross-platform support.
///
/// Usage:
/// ```swift
/// // From bundled JSON file (uses BayNavigatorCore bundle by default)
/// LottieView(name: "loading")
///
/// // With configuration
/// LottieView(name: "success", loopMode: .playOnce, speed: 1.5)
///
/// // From URL
/// LottieView(url: URL(string: "https://example.com/animation.json")!)
///
/// // Using presets (recommended)
/// LottieView(preset: .loading)
/// LottieView(preset: .success, loopMode: .playOnce)
/// ```
public struct LottieView: View {
    private let source: LottieSource
    private let loopMode: LottieLoopMode
    private let speed: CGFloat
    private let contentMode: LottieContentMode

    public enum LottieSource {
        case name(String, Bundle)
        case url(URL)
        case animation(LottieAnimation)
    }

    /// Content mode for how the animation fits in its bounds
    public enum LottieContentMode {
        case fit
        case fill
    }

    /// Initialize with a bundled animation file name
    /// - Parameters:
    ///   - name: The name of the Lottie JSON file (without extension)
    ///   - bundle: The bundle containing the animation (defaults to BayNavigatorCore module bundle)
    ///   - loopMode: How the animation should loop (defaults to loop)
    ///   - speed: Playback speed multiplier (defaults to 1.0)
    ///   - contentMode: How the animation fits in its bounds (defaults to fit)
    public init(
        name: String,
        bundle: Bundle? = nil,
        loopMode: LottieLoopMode = .loop,
        speed: CGFloat = 1.0,
        contentMode: LottieContentMode = .fit
    ) {
        // Default to module bundle if not specified
        let resolvedBundle = bundle ?? Bundle.module
        self.source = .name(name, resolvedBundle)
        self.loopMode = loopMode
        self.speed = speed
        self.contentMode = contentMode
    }

    /// Initialize with a URL to a remote Lottie animation
    /// - Parameters:
    ///   - url: The URL of the Lottie JSON file
    ///   - loopMode: How the animation should loop (defaults to loop)
    ///   - speed: Playback speed multiplier (defaults to 1.0)
    ///   - contentMode: How the animation fits in its bounds (defaults to fit)
    public init(
        url: URL,
        loopMode: LottieLoopMode = .loop,
        speed: CGFloat = 1.0,
        contentMode: LottieContentMode = .fit
    ) {
        self.source = .url(url)
        self.loopMode = loopMode
        self.speed = speed
        self.contentMode = contentMode
    }

    /// Initialize with a pre-loaded LottieAnimation
    /// - Parameters:
    ///   - animation: The pre-loaded LottieAnimation
    ///   - loopMode: How the animation should loop (defaults to loop)
    ///   - speed: Playback speed multiplier (defaults to 1.0)
    ///   - contentMode: How the animation fits in its bounds (defaults to fit)
    public init(
        animation: LottieAnimation,
        loopMode: LottieLoopMode = .loop,
        speed: CGFloat = 1.0,
        contentMode: LottieContentMode = .fit
    ) {
        self.source = .animation(animation)
        self.loopMode = loopMode
        self.speed = speed
        self.contentMode = contentMode
    }

    public var body: some View {
        LottieViewRepresentable(
            source: source,
            loopMode: loopMode,
            speed: speed,
            contentMode: contentMode
        )
    }
}

// MARK: - Platform-specific implementation

#if os(iOS) || os(visionOS)
import UIKit

private struct LottieViewRepresentable: UIViewRepresentable {
    let source: LottieView.LottieSource
    let loopMode: LottieLoopMode
    let speed: CGFloat
    let contentMode: LottieView.LottieContentMode

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.contentMode = contentMode == .fit ? .scaleAspectFit : .scaleAspectFill
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.backgroundBehavior = .pauseAndRestore
        return animationView
    }

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        loadAnimation(into: animationView)
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.contentMode = contentMode == .fit ? .scaleAspectFit : .scaleAspectFill

        if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }

    private func loadAnimation(into animationView: LottieAnimationView) {
        switch source {
        case .name(let name, let bundle):
            animationView.animation = LottieAnimation.named(name, bundle: bundle)
        case .url(let url):
            LottieAnimation.loadedFrom(url: url) { animation in
                DispatchQueue.main.async {
                    animationView.animation = animation
                    animationView.play()
                }
            }
        case .animation(let animation):
            animationView.animation = animation
        }
    }
}

#elseif os(macOS)
import AppKit

private struct LottieViewRepresentable: NSViewRepresentable {
    let source: LottieView.LottieSource
    let loopMode: LottieLoopMode
    let speed: CGFloat
    let contentMode: LottieView.LottieContentMode

    func makeNSView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.backgroundBehavior = .pauseAndRestore
        return animationView
    }

    func updateNSView(_ animationView: LottieAnimationView, context: Context) {
        loadAnimation(into: animationView)
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed

        if !animationView.isAnimationPlaying {
            animationView.play()
        }
    }

    private func loadAnimation(into animationView: LottieAnimationView) {
        switch source {
        case .name(let name, let bundle):
            animationView.animation = LottieAnimation.named(name, bundle: bundle)
        case .url(let url):
            LottieAnimation.loadedFrom(url: url) { animation in
                DispatchQueue.main.async {
                    animationView.animation = animation
                    animationView.play()
                }
            }
        case .animation(let animation):
            animationView.animation = animation
        }
    }
}
#endif

// MARK: - Convenience extensions

public extension LottieView {
    /// Common animation presets for BayNavigator
    enum AnimationPreset: String, CaseIterable {
        case loading = "loading"
        case success = "success"
        case error = "error"
        case empty = "empty_state"
        case welcome = "welcome"
        case confetti = "confetti"
        case mapPin = "map_pin"
        case search = "search"
        case heart = "heart"
        case checkmark = "checkmark"

        /// Default loop mode for this preset
        var defaultLoopMode: LottieLoopMode {
            switch self {
            case .loading, .empty, .welcome, .search:
                return .loop
            case .success, .error, .confetti, .mapPin, .heart, .checkmark:
                return .playOnce
            }
        }
    }

    /// Initialize with a preset animation from the BayNavigatorCore bundle
    /// - Parameters:
    ///   - preset: The animation preset to use
    ///   - loopMode: How the animation should loop (defaults to preset's default)
    ///   - speed: Playback speed multiplier (defaults to 1.0)
    init(preset: AnimationPreset, loopMode: LottieLoopMode? = nil, speed: CGFloat = 1.0) {
        self.init(
            name: preset.rawValue,
            bundle: Bundle.module,
            loopMode: loopMode ?? preset.defaultLoopMode,
            speed: speed
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Lottie Animations") {
    VStack(spacing: 20) {
        Text("Lottie Animations")
            .font(.headline)

        HStack(spacing: 20) {
            VStack {
                LottieView(preset: .loading)
                    .frame(width: 80, height: 80)
                Text("Loading")
                    .font(.caption)
            }

            VStack {
                LottieView(preset: .success)
                    .frame(width: 80, height: 80)
                Text("Success")
                    .font(.caption)
            }

            VStack {
                LottieView(preset: .empty)
                    .frame(width: 80, height: 80)
                Text("Empty")
                    .font(.caption)
            }
        }
    }
    .padding()
}
#endif
