import SwiftUI
import BayNavigatorCore

/// WCAG 2.2 AAA Accessibility Settings View
struct AccessibilitySettingsView: View {
    @Environment(AccessibilityViewModel.self) private var accessibilityVM
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            presetsSection
            visionSection
            motionSection
            readingSection
            interactionSection
            audioSection
            systemInfoSection
            resetSection
        }
        .navigationTitle("Accessibility")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear {
            accessibilityVM.updateSystemPreferences(
                reduceMotion: systemReduceMotion,
                reduceTransparency: systemReduceTransparency
            )
        }
        .confirmationDialog(
            "Reset Accessibility Settings",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Defaults", role: .destructive) {
                Task {
                    await accessibilityVM.resetToDefaults()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all accessibility settings to their default values.")
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        Section {
            ForEach(AccessibilityPreset.allCases) { preset in
                Button {
                    accessibilityVM.applyPreset(preset)
                } label: {
                    HStack {
                        Image(systemName: preset.icon)
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.displayName)
                                .foregroundStyle(.primary)
                            Text(preset.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if accessibilityVM.settings.activePreset == preset {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appSuccess)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(preset.displayName) preset")
                .accessibilityHint(preset.description)
            }
        } header: {
            Text("Quick Presets")
        } footer: {
            Text("Presets configure multiple settings at once. Individual changes below will override the preset.")
        }
    }

    // MARK: - Vision Section

    private var visionSection: some View {
        Section {
            // Text Scale
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Text Size", systemImage: "textformat.size")
                    Spacer()
                    Text(String(format: "%.0f%%", accessibilityVM.settings.textScale * 100))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { accessibilityVM.settings.textScale },
                        set: { accessibilityVM.setTextScale($0) }
                    ),
                    in: 0.8 ... 2.0,
                    step: 0.1
                ) {
                    Text("Text Scale")
                } minimumValueLabel: {
                    Text("A")
                        .font(.caption2)
                } maximumValueLabel: {
                    Text("A")
                        .font(.title3)
                }
                .accessibilityValue("\(Int(accessibilityVM.settings.textScale * 100)) percent")
            }
            .padding(.vertical, 4)

            // Bold Text
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.boldText },
                set: { accessibilityVM.setBoldText($0) }
            )) {
                Label("Bold Text", systemImage: "bold")
            }

            // High Contrast
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.highContrastMode },
                set: { accessibilityVM.setHighContrastMode($0) }
            )) {
                Label("High Contrast", systemImage: "circle.lefthalf.filled")
            }

            // Reduce Transparency
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.reduceTransparency },
                set: { accessibilityVM.setReduceTransparency($0) }
            )) {
                Label("Reduce Transparency", systemImage: "square.on.square.dashed")
            }

            // Dyslexia Font
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.dyslexiaFont },
                set: { accessibilityVM.setDyslexiaFont($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Dyslexia-Friendly Font", systemImage: "textformat.abc")
                    Text("Uses OpenDyslexic font throughout the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Vision")
        }
    }

    // MARK: - Motion Section

    private var motionSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.reduceMotion },
                set: { accessibilityVM.setReduceMotion($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Reduce Motion", systemImage: "figure.walk.motion")
                    if accessibilityVM.systemReduceMotion {
                        Text("System setting is also enabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.pauseAnimations },
                set: { accessibilityVM.setPauseAnimations($0) }
            )) {
                Label("Pause Animations", systemImage: "pause.circle")
            }
        } header: {
            Text("Motion")
        } footer: {
            Text("Reduces motion effects and pauses auto-playing animations for those sensitive to motion.")
        }
    }

    // MARK: - Reading Section

    private var readingSection: some View {
        Section {
            // Line Height
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Line Height", systemImage: "text.alignleft")
                    Spacer()
                    Text(String(format: "%.1f×", accessibilityVM.settings.lineHeightMultiplier))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { accessibilityVM.settings.lineHeightMultiplier },
                        set: { accessibilityVM.setLineHeightMultiplier($0) }
                    ),
                    in: 1.0 ... 2.0,
                    step: 0.1
                ) {
                    Text("Line Height")
                }
                .accessibilityValue("\(String(format: "%.1f", accessibilityVM.settings.lineHeightMultiplier)) times")
            }
            .padding(.vertical, 4)

            // Letter Spacing
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Letter Spacing", systemImage: "character")
                    Spacer()
                    Text(String(format: "%.2f", accessibilityVM.settings.letterSpacing))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { accessibilityVM.settings.letterSpacing },
                        set: { accessibilityVM.setLetterSpacing($0) }
                    ),
                    in: 0 ... 0.1,
                    step: 0.01
                ) {
                    Text("Letter Spacing")
                }
            }
            .padding(.vertical, 4)

            // Word Spacing
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Word Spacing", systemImage: "text.word.spacing")
                    Spacer()
                    Text(String(format: "%.2f", accessibilityVM.settings.wordSpacing))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { accessibilityVM.settings.wordSpacing },
                        set: { accessibilityVM.setWordSpacing($0) }
                    ),
                    in: 0 ... 0.2,
                    step: 0.02
                ) {
                    Text("Word Spacing")
                }
            }
            .padding(.vertical, 4)

            // Simple Language Mode
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.simpleLanguageMode },
                set: { accessibilityVM.setSimpleLanguageMode($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Simple Language", systemImage: "text.bubble")
                    Text("Shows simplified descriptions when available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Reading & Display")
        } footer: {
            Text("Adjust text spacing for improved readability per WCAG 2.2 guidelines.")
        }
    }

    // MARK: - Interaction Section

    private var interactionSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.largerTouchTargets },
                set: { accessibilityVM.setLargerTouchTargets($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Larger Touch Targets", systemImage: "hand.tap")
                    Text("Minimum 48×48 point tap areas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.extendedTimeouts },
                set: { accessibilityVM.setExtendedTimeouts($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Extended Timeouts", systemImage: "clock.badge.checkmark")
                    Text("Doubles time allowed for timed interactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Interaction")
        }
    }

    // MARK: - Audio Section

    private var audioSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.preferCaptions },
                set: { accessibilityVM.setPreferCaptions($0) }
            )) {
                Label("Prefer Captions", systemImage: "captions.bubble")
            }

            Toggle(isOn: Binding(
                get: { accessibilityVM.settings.visualAlerts },
                set: { accessibilityVM.setVisualAlerts($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Visual Alerts", systemImage: "light.beacon.max")
                    Text("Flash screen for important audio alerts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Audio & Captions")
        }
    }

    // MARK: - System Info Section

    private var systemInfoSection: some View {
        Section {
            LabeledContent {
                Text(systemReduceMotion ? "On" : "Off")
                    .foregroundStyle(.secondary)
            } label: {
                Label("System Reduce Motion", systemImage: "gear")
            }

            LabeledContent {
                Text(systemReduceTransparency ? "On" : "Off")
                    .foregroundStyle(.secondary)
            } label: {
                Label("System Reduce Transparency", systemImage: "gear")
            }

            LabeledContent {
                Text(dynamicTypeSize.description)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Dynamic Type Size", systemImage: "textformat.size")
            }

            Button {
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #elseif os(macOS)
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.universalaccess") {
                    NSWorkspace.shared.open(url)
                }
                #endif
            } label: {
                HStack {
                    Label("Open System Settings", systemImage: "arrow.up.forward.app")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("System Accessibility")
        } footer: {
            Text("Bay Navigator respects your system accessibility settings. Additional options above provide finer control.")
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Defaults")
                }
                .foregroundStyle(Color.appDanger)
            }
            .disabled(accessibilityVM.settings.isDefault)
        }
    }
}

// MARK: - Dynamic Type Size Description Extension

extension DynamicTypeSize {
    var description: String {
        switch self {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (Default)"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "XX Large"
        case .xxxLarge: return "XXX Large"
        case .accessibility1: return "Accessibility 1"
        case .accessibility2: return "Accessibility 2"
        case .accessibility3: return "Accessibility 3"
        case .accessibility4: return "Accessibility 4"
        case .accessibility5: return "Accessibility 5"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        AccessibilitySettingsView()
    }
    .environment(AccessibilityViewModel())
}
