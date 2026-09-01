import SwiftUI

private enum AppTab: String {
    case home
    case guide
    case catalog
    case challenge
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedTab: AppTab

    init() {
        let requestedTab = UserDefaults.standard.string(forKey: "ui-test-tab")
            .flatMap(AppTab.init(rawValue:))
        _selectedTab = State(initialValue: requestedTab ?? .home)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("造字堂", systemImage: "seal")
            }
            .tag(AppTab.home)

            NavigationStack {
                LearningLibraryView()
            }
            .tabItem {
                Label("導讀", systemImage: "books.vertical.fill")
            }
            .tag(AppTab.guide)

            NavigationStack {
                CharacterCatalogView()
            }
            .tabItem {
                Label("字庫", systemImage: "character.book.closed.fill")
            }
            .tag(AppTab.catalog)

            NavigationStack {
                ChallengeView()
            }
            .tabItem {
                Label("闖關", systemImage: "flag.checkered")
            }
            .tag(AppTab.challenge)
        }
        .alert("系統提示", isPresented: errorBinding) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(model.loadError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.loadError != nil },
            set: { isPresented in
                if !isPresented { model.dismissError() }
            }
        )
    }
}

#Preview {
    RootView()
        .environmentObject(AppModel())
}
