import SwiftUI

struct ContentView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @Environment(UserPrefsViewModel.self) private var userPrefsViewModel
    @State private var selectedTab = 0

    var body: some View {
        @Bindable var userPrefs = userPrefsViewModel

        TabView(selection: $selectedTab) {
            ForYouView()
                .tabItem {
                    Label("For You", systemImage: "sparkles")
                }
                .tag(0)

            HomeView()
                .tabItem {
                    Label("Directory", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            FavoritesView()
                .tabItem {
                    Label("Saved", systemImage: "heart.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        // Smart Assistant chat panel removed - AI search is now integrated
        // directly into the Directory search bar (matching website behavior)
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $userPrefs.showOnboarding) {
            OnboardingView()
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
        .environment(UserPrefsViewModel())
}
