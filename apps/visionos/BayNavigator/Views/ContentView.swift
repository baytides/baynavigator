import SwiftUI

struct ContentView: View {
    @Environment(ProgramsViewModel.self) private var viewModel
    @Environment(UserPrefsViewModel.self) private var userPrefsViewModel
    @State private var selectedTab = 0
    @State private var showSmartAssistant = false

    var body: some View {
        @Bindable var userPrefs = userPrefsViewModel

        ZStack(alignment: .bottomTrailing) {
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

            // Smart Assistant floating button
            Button {
                showSmartAssistant = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.appPrimary)
                        .frame(width: 56, height: 56)

                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)
            .padding(.trailing, 24)
            .padding(.bottom, 100)
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $userPrefs.showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showSmartAssistant) {
            SmartAssistantView(onProgramSelected: { program in
                // Navigate to program detail - could be enhanced
                showSmartAssistant = false
            })
            .frame(minWidth: 400, idealWidth: 500, maxWidth: 600,
                   minHeight: 500, idealHeight: 700, maxHeight: 800)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(ProgramsViewModel())
        .environment(SettingsViewModel())
        .environment(UserPrefsViewModel())
}
