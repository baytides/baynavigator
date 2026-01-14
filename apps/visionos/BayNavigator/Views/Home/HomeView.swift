import SwiftUI

struct HomeView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showingFilters = false
    @State private var showingSort = false
    @State private var selectedProgram: Program?
    @State private var searchText = ""

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.programs.isEmpty {
                    ProgressView("Loading programs...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error, viewModel.programs.isEmpty {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.loadData(forceRefresh: true)
                        }
                    }
                } else {
                    programList
                }
            }
            .navigationTitle("Bay Navigator")
            .navigationDestination(item: $selectedProgram) { program in
                ProgramDetailView(program: program)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if viewModel.filterState.filterCount > 0 {
                                Text("\(viewModel.filterState.filterCount)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .accessibilityLabel(viewModel.filterState.filterCount > 0
                        ? AccessibilityLabels.filterActive(viewModel.filterState.filterCount)
                        : AccessibilityLabels.filter)
                    .accessibilityHint("Double tap to open filter options")
                }

                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel(AccessibilityLabels.sort)
                    .accessibilityHint("Double tap to change sort order")
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheetView()
            }
            .refreshable {
                await viewModel.loadData(forceRefresh: true)
            }
        }
    }

    // Adaptive grid columns for visionOS spatial layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 320, maximum: 400), spacing: 16)
    ]

    private var programList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                // AI search message banner
                if let aiMessage = viewModel.aiSearchMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                        Text(aiMessage)
                            .font(.subheadline)
                        Spacer()
                        Button {
                            viewModel.clearAISearch()
                            searchText = ""
                            AccessibilityAnnouncement.announce("AI search cleared")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("AI search result: \(aiMessage)")
                }

                // Results count
                HStack {
                    if viewModel.aiSearchResults != nil {
                        Text("\(viewModel.filteredPrograms.count) AI result\(viewModel.filteredPrograms.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                            .accessibilityLabel("AI found \(viewModel.filteredPrograms.count) results")
                    } else {
                        Text("\(viewModel.filteredPrograms.count) program\(viewModel.filteredPrograms.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(AccessibilityLabels.resultsCount(viewModel.filteredPrograms.count))
                    }

                    Spacer()

                    if viewModel.filterState.hasFilters {
                        Button("Clear") {
                            viewModel.clearFilters()
                            AccessibilityAnnouncement.announce("Filters cleared")
                        }
                        .font(.subheadline)
                        .accessibilityLabel("Clear all filters")
                        .accessibilityHint("Double tap to remove all active filters")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .accessibilityElement(children: .contain)

                if viewModel.filteredPrograms.isEmpty {
                    emptyState
                } else {
                    // Grid layout for tiles
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(viewModel.filteredPrograms) { program in
                            ProgramCardView(
                                program: program,
                                isFavorite: viewModel.isFavorite(program.id),
                                onTap: {
                                    selectedProgram = program
                                },
                                onFavoriteToggle: {
                                    viewModel.toggleFavorite(program.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var searchBar: some View {
        @Bindable var viewModel = viewModel

        return HStack {
            // Search/AI indicator
            if viewModel.isAISearching {
                ProgressView()
                    .scaleEffect(0.8)
                    .accessibilityLabel("AI search in progress")
            } else if settingsViewModel.aiSearchEnabled {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                    .accessibilityLabel("AI search enabled")
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            TextField(
                settingsViewModel.aiSearchEnabled ? "Ask anything or search..." : "Search programs...",
                text: $searchText
            )
            .textFieldStyle(.plain)
            .accessibilityLabel(AccessibilityLabels.search)
            .accessibilityHint(settingsViewModel.aiSearchEnabled
                ? "Enter keywords or ask a question to search programs"
                : "Enter keywords to search programs")
            .onSubmit {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                // Clear AI results when user starts typing something new
                if viewModel.aiSearchResults != nil && newValue.isEmpty {
                    viewModel.clearAISearch()
                }
                // Update regular search as user types
                viewModel.setSearchQuery(newValue)
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.setSearchQuery("")
                    viewModel.clearAISearch()
                    AccessibilityAnnouncement.announce("Search cleared")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44) // WCAG 2.5.5: 44pt minimum touch target
                .accessibilityLabel("Clear search")
                .accessibilityHint("Double tap to clear search text")
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        Task {
            let usedAI = await viewModel.performAISearch(
                searchText,
                aiEnabled: settingsViewModel.aiSearchEnabled
            )
            if usedAI {
                AccessibilityAnnouncement.announce("AI search complete, \(viewModel.filteredPrograms.count) results found")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No programs found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.filterState.hasFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Failed to load programs")
                .font(.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    HomeView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
        .environment(UserPrefsViewModel())
}
