import SwiftUI

private enum AppTab: String {
    case home
    case guide
    case catalog
    case challenge
    case stats
}

private enum FeatureRoute: String {
    case journey, flash, daily, battle, classroom, parent
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedTab: AppTab
    private let requestedFeature: FeatureRoute?

    init() {
        let requestedTab = UserDefaults.standard.string(forKey: "ui-test-tab")
            .flatMap(AppTab.init(rawValue:))
        requestedFeature = UserDefaults.standard.string(forKey: "ui-test-feature")
            .flatMap(FeatureRoute.init(rawValue:))
        _selectedTab = State(initialValue: requestedTab ?? .home)
    }

    var body: some View {
        Group {
            if let requestedFeature {
                NavigationStack { featureView(requestedFeature) }
            } else {
                tabs
            }
        }
        .modifier(ParentReadingSizeModifier())
        .alert("系統提示", isPresented: errorBinding) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(model.loadError ?? "")
        }
    }

    private var tabs: some View {
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

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("紀錄", systemImage: "chart.bar.fill")
            }
            .tag(AppTab.stats)
        }
    }

    @ViewBuilder
    private func featureView(_ feature: FeatureRoute) -> some View {
        switch feature {
        case .journey: JourneyView()
        case .flash: FlashcardView()
        case .daily: JourneyTrialView(chapter: nil, dailyCount: 12)
        case .battle: BattleView()
        case .classroom: ClassroomView()
        case .parent: ParentGuideView()
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

private struct ParentReadingSizeModifier: ViewModifier {
    @AppStorage("parent-reading-large") private var useLargeReading = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if useLargeReading { content.dynamicTypeSize(.accessibility1) }
        else { content }
    }
}

#Preview {
    RootView()
        .environmentObject(AppModel())
}
