import SwiftUI
import BayNavigatorCore

/// Full Directory view with NavigationStack (use when displayed as a tab)
struct DirectoryView: View {
    var body: some View {
        NavigationStack {
            DirectoryViewContent()
        }
    }
}

/// Directory content without NavigationStack (use when pushed onto existing navigation)
struct DirectoryViewContent: View {
    @Environment(ProgramsViewModel.self) private var programsVM
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showSort = false

    var body: some View {
        Group {
            if programsVM.isLoading && programsVM.programs.isEmpty {
                loadingView
            } else if let error = programsVM.error, programsVM.programs.isEmpty {
                errorView(error)
            } else {
                programsList
            }
        }
        .navigationTitle("Directory")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search programs...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        #elseif os(macOS)
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search programs...")
        .toolbar {
            ToolbarItem {
                filterButton
            }
        }
        #elseif os(visionOS)
        .searchable(text: $searchText, prompt: "Search programs...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        #endif
        .refreshable {
            await programsVM.loadData(forceRefresh: true)
        }
        .onChange(of: searchText) { _, newValue in
            programsVM.setSearchQuery(newValue)
        }
        .onChange(of: programsVM.filteredPrograms.count) { _, newCount in
            // Announce filter results to VoiceOver
            Task { @MainActor in
                AccessibilityService.shared.announceFilterChange(resultCount: newCount)
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheetView(filter: programsVM.filterState)
                .environment(programsVM)
        }
        .confirmationDialog("Sort By", isPresented: $showSort) {
            ForEach(SortOption.allCases) { option in
                Button(option.rawValue) {
                    programsVM.sortOption = option
                }
            }
        }
    }

    // MARK: - Subviews

    private var filterButton: some View {
        Menu {
            Button {
                showFilters = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }

            Divider()

            Menu("Sort By") {
                ForEach(SortOption.allCases) { option in
                    Button {
                        programsVM.sortOption = option
                    } label: {
                        if programsVM.sortOption == option {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: programsVM.filterState.hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.appPrimary)
        }
        .accessibilityLabel(programsVM.filterState.hasFilters ? SemanticLabels.filterActive(programsVM.filterState.filterCount) : SemanticLabels.filter)
        .accessibilityHint("Opens filter and sort options")
    }

    private var programsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // AI Search message banner
                if let aiMessage = programsVM.aiSearchMessage {
                    aiMessageBanner(aiMessage)
                }

                // Active filters summary
                if programsVM.filterState.hasFilters {
                    activeFiltersBanner
                }

                // Results count
                resultsHeader

                // Programs
                ForEach(programsVM.filteredPrograms) { program in
                    NavigationLink(value: program) {
                        ProgramCard(program: program)
                    }
                    .buttonStyle(.plain)
                }

                // Empty state
                if programsVM.filteredPrograms.isEmpty {
                    noResultsView
                }
            }
            .padding()
        }
        .navigationDestination(for: Program.self) { program in
            ProgramDetailView(program: program)
        }
    }

    private func aiMessageBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.appAccent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Assistant")
                    .font(.caption.bold())
                    .foregroundStyle(Color.appAccent)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(.subheadline)
            }

            Spacer()

            Button {
                programsVM.clearAISearch()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss AI message")
            .accessibilityHint("Clears the AI search suggestion")
        }
        .padding()
        #if os(iOS)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        #else
        .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        #endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel("AI Assistant suggestion: \(message)")
    }

    private var activeFiltersBanner: some View {
        HStack {
            Text("\(programsVM.filterState.filterCount) filters active")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear All") {
                programsVM.clearFilters()
            }
            .font(.subheadline)
            .foregroundStyle(Color.appPrimary)
            .accessibilityLabel("Clear all filters")
            .accessibilityHint("Removes all active filters")
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
    }

    private var resultsHeader: some View {
        HStack {
            Text("\(programsVM.filteredPrograms.count) programs")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(programsVM.sortOption.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SemanticLabels.resultsCount(programsVM.filteredPrograms.count) + ", sorted by \(programsVM.sortOption.rawValue)")
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .accessibilityHidden(true)
            Text("Loading programs...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SemanticLabels.loadingPrograms)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color.appDanger)
                .accessibilityHidden(true)

            Text("Unable to Load Programs")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await programsVM.loadData(forceRefresh: true)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPrimary)
            .accessibilityHint("Attempts to reload programs")
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Error loading programs: \(error)")
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Programs Found")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if programsVM.filterState.hasFilters {
                Button("Clear Filters") {
                    programsVM.clearFilters()
                }
                .buttonStyle(.bordered)
                .tint(.appPrimary)
                .accessibilityHint("Removes all filters to show all programs")
            }
        }
        .padding(40)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("No programs found. Try adjusting your search or filters.")
    }
}

#Preview {
    DirectoryView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
}
