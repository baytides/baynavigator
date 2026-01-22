import SwiftUI
import BayNavigatorCore

/// Full Settings view with NavigationStack (use when displayed as a tab)
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            SettingsViewContent()
        }
    }
}

/// Settings content without NavigationStack (use when pushed onto existing navigation)
struct SettingsViewContent: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(UserPrefsViewModel.self) private var userPrefsVM
    @Environment(AccessibilityViewModel.self) private var accessibilityVM
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var showImmersiveSpace = false
    #endif

    @State private var showProxyConfig = false
    @State private var showProfileEdit = false
    @State private var proxyHost = ""
    @State private var proxyPort = ""
    @State private var proxyType: ProxyType = .socks5
    @State private var testingConnection = false
    @State private var connectionTestResult: PrivacyTestResult?
    @State private var cacheSize = "Calculating..."

    var body: some View {
        Form {
            #if os(visionOS)
            spatialExperienceSection
            #endif

            profileSection
            appInfoSection
            appearanceSection
            accessibilitySection
            searchSection
            languageSection
            privacySection
            storageSection
            supportSection
            legalSection
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            cacheSize = await settingsVM.cacheSize
        }
    }

    // MARK: - Sections

    #if os(visionOS)
    private var spatialExperienceSection: some View {
        Section {
            Toggle(isOn: $showImmersiveSpace) {
                Label("Immersive Welcome Space", systemImage: "visionpro")
            }
            .onChange(of: showImmersiveSpace) { _, newValue in
                Task {
                    if newValue {
                        await openImmersiveSpace(id: "WelcomeSpace")
                    } else {
                        await dismissImmersiveSpace()
                    }
                }
            }
        } header: {
            Text("Spatial Experience")
        } footer: {
            Text("Open an immersive environment with floating program categories.")
        }
    }
    #endif

    private var profileSection: some View {
        Section("Your Profile") {
            // Show saved profile information if available
            if userPrefsVM.hasPreferences {
                // Profile header with avatar
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(userPrefsVM.profileColor)
                            .frame(width: 50, height: 50)

                        Text(userPrefsVM.firstName?.prefix(1).uppercased() ?? "?")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if let firstName = userPrefsVM.firstName, !firstName.isEmpty {
                            Text(firstName)
                                .font(.headline)
                        }

                        if let location = userPrefsVM.displayLocation {
                            Text(location)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                // Birth Year / Age
                if let birthYear = userPrefsVM.birthYear {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    let age = currentYear - birthYear
                    LabeledContent {
                        Text("\(age) years old")
                    } label: {
                        Label("Age", systemImage: "calendar")
                    }
                }

                // Interests/Groups
                if !userPrefsVM.selectedGroups.isEmpty {
                    let groupNames = userPrefsVM.getGroupNames(from: programsVM.groups)
                    if !groupNames.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Interests", systemImage: "heart.fill")
                            FlowLayout(spacing: 6) {
                                ForEach(groupNames, id: \.self) { name in
                                    Text(name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appPrimary.opacity(0.1))
                                        .foregroundStyle(Color.appPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Qualifications
                if !userPrefsVM.qualifications.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Qualifications", systemImage: "checkmark.seal.fill")
                        FlowLayout(spacing: 6) {
                            ForEach(userPrefsVM.qualifications, id: \.self) { qual in
                                Text(formatQualification(qual))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.appAccent.opacity(0.1))
                                    .foregroundStyle(Color.appAccent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // No profile set up yet
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("No profile set up yet")
                        .foregroundStyle(.secondary)
                }
            }

            // Edit button - use lightweight sheet for existing profiles, onboarding for new users
            Button {
                if userPrefsVM.hasPreferences {
                    showProfileEdit = true
                } else {
                    userPrefsVM.reopenOnboarding()
                }
            } label: {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(Color.appPrimary)
                    Text(userPrefsVM.hasPreferences ? "Edit Profile" : "Set Up Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// Format qualification ID to display name
    private func formatQualification(_ qual: String) -> String {
        qual.split(separator: "_")
            .map { String($0).capitalized }
            .joined(separator: " ")
    }

    private var appInfoSection: some View {
        Section("App Info") {
            LabeledContent("Version", value: SettingsViewModel.appVersion)

            if let metadata = programsVM.metadata {
                LabeledContent("Database Version", value: metadata.version)
                LabeledContent("Last Updated", value: metadata.formattedGeneratedAt)
                LabeledContent("Programs", value: "\(metadata.totalPrograms)")
            }

            Button {
                Task {
                    await programsVM.loadData(forceRefresh: true)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.appPrimary)
                    Text("Refresh Data")
                }
            }
            .disabled(programsVM.isLoading)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settingsVM.themeMode },
                set: { settingsVM.themeMode = $0 }
            )) {
                ForEach(SettingsViewModel.ThemeMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            #if os(visionOS)
            Toggle(isOn: Binding(
                get: { settingsVM.warmModeEnabled },
                set: { settingsVM.warmModeEnabled = $0 }
            )) {
                Label("Warm Mode", systemImage: "sun.max")
            }
            #endif
        }
    }

    private var accessibilitySection: some View {
        Section {
            NavigationLink {
                AccessibilitySettingsView()
                    .environment(accessibilityVM)
            } label: {
                HStack {
                    Label("Accessibility", systemImage: "accessibility")
                    Spacer()
                    if accessibilityVM.hasCustomizations {
                        Text("Customized")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Accessibility")
        } footer: {
            Text("WCAG 2.2 AAA compliant settings for vision, motion, reading, and interaction.")
        }
    }

    private var searchSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { settingsVM.aiSearchEnabled },
                set: { settingsVM.aiSearchEnabled = $0 }
            )) {
                HStack {
                    Label("AI Features", systemImage: "sparkles")
                    Text("BETA")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appAccent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        } header: {
            Text("AI")
        } footer: {
            Text("Enable AI-powered search and Ask Carl assistant. When disabled, Ask Carl will be unavailable.")
        }
    }

    private var languageSection: some View {
        Section("Language") {
            Picker("Language", selection: Binding(
                get: { settingsVM.currentLocale },
                set: { settingsVM.currentLocale = $0 }
            )) {
                ForEach(AppLocale.allCases) { locale in
                    HStack {
                        Text(locale.flag)
                        Text(locale.nativeName)
                    }
                    .tag(locale)
                }
            }
        }
    }

    private var privacySection: some View {
        Section {
            // Custom proxy
            Button {
                showProxyConfig = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundStyle(Color.appPrimary)
                    VStack(alignment: .leading) {
                        Text("Custom Proxy")
                        if let config = settingsVM.proxyConfig {
                            Text(config.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Connection test
            Button {
                Task {
                    testingConnection = true
                    connectionTestResult = await settingsVM.testPrivacyConnection()
                    testingConnection = false
                }
            } label: {
                HStack {
                    if testingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(Color.appInfo)
                    }
                    Text("Test Connection")
                }
            }
            .disabled(testingConnection)

            // Test result
            if let result = connectionTestResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.success ? Color.appSuccess : Color.appDanger)
                    VStack(alignment: .leading) {
                        Text(result.message)
                            .font(.caption)
                        Text("\(result.latencyMs)ms latency")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Advanced Privacy")
        } footer: {
            Text("Enhanced privacy options for censorship circumvention.")
        }
        .sheet(isPresented: $showProxyConfig) {
            ProxyConfigSheet(
                host: $proxyHost,
                port: $proxyPort,
                type: $proxyType
            )
            .environment(settingsVM)
        }
        .sheet(isPresented: $showProfileEdit) {
            ProfileEditSheet()
                .environment(userPrefsVM)
        }
    }

    private var storageSection: some View {
        Section {
            LabeledContent("Cache Size", value: cacheSize)

            Button(role: .destructive) {
                Task {
                    await settingsVM.clearCache()
                    cacheSize = await settingsVM.cacheSize
                }
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Cache")
                }
                .foregroundStyle(Color.appDanger)
            }
        } header: {
            Text("Storage")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Link(destination: SettingsViewModel.donateURL) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Donate")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.websiteURL) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(Color.appPrimary)
                    Text("Website")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.githubURL) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.secondary)
                    Text("Source Code")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: SettingsViewModel.feedbackURL) {
                HStack {
                    Image(systemName: "ladybug.fill")
                        .foregroundStyle(Color.appDanger)
                    Text("Report a Bug")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            NavigationLink {
                WebContentView(title: "Terms of Service", url: SettingsViewModel.termsURL)
            } label: {
                Text("Terms of Service")
            }

            NavigationLink {
                WebContentView(title: "Privacy Policy", url: SettingsViewModel.privacyURL)
            } label: {
                Text("Privacy Policy")
            }

            NavigationLink {
                WebContentView(title: "Credits", url: SettingsViewModel.creditsURL)
            } label: {
                Text("Credits")
            }
        }
    }
}

// MARK: - Proxy Config Sheet

struct ProxyConfigSheet: View {
    @Binding var host: String
    @Binding var port: String
    @Binding var type: ProxyType

    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Proxy Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ProxyType.allCases) { proxyType in
                            Text(proxyType.displayName).tag(proxyType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Connection") {
                    TextField("Host (e.g., 127.0.0.1)", text: $host)
                        .textContentType(.URL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif

                    TextField("Port (e.g., 9050)", text: $port)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }

                Section {
                    Button("Save Configuration") {
                        if let portNum = Int(port), portNum > 0, portNum <= 65535, !host.isEmpty {
                            Task {
                                await settingsVM.setProxyConfig(ProxyConfig(host: host, port: portNum, type: type))
                                dismiss()
                            }
                        }
                    }
                    .disabled(host.isEmpty || port.isEmpty)

                    if settingsVM.proxyConfig != nil {
                        Button("Clear Configuration", role: .destructive) {
                            Task {
                                await settingsVM.clearProxyConfig()
                                host = ""
                                port = ""
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Proxy Configuration")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            if let config = settingsVM.proxyConfig {
                host = config.host
                port = String(config.port)
                type = config.type
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(SettingsViewModel())
        .environment(ProgramsViewModel())
        .environment(UserPrefsViewModel())
        .environment(AccessibilityViewModel())
}
