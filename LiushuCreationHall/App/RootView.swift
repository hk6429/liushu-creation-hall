import SwiftUI

private enum AppTab: String {
    case home
    case guide
    case catalog
    case challenge
    case stats
}

private enum FeatureRoute: String {
    case seal, journey, flash, daily, battle, classroom, parent, challenge, practice
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab
    private let requestedFeature: FeatureRoute?
    private let usageTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isResetRun = arguments.contains("-ui-test-reset")
        let requestedTab = Self.argumentValue(after: "-ui-test-tab", in: arguments)
            .flatMap(AppTab.init(rawValue:))
            ?? (isResetRun ? nil : UserDefaults.standard.string(forKey: "ui-test-tab").flatMap(AppTab.init(rawValue:)))
        requestedFeature = Self.argumentValue(after: "-ui-test-feature", in: arguments)
            .flatMap(FeatureRoute.init(rawValue:))
            ?? (isResetRun ? nil : UserDefaults.standard.string(forKey: "ui-test-feature").flatMap(FeatureRoute.init(rawValue:)))
        _selectedTab = State(initialValue: requestedTab ?? .home)
    }

    private static func argumentValue(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
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
        .modifier(ParentExperienceModifier())
        .alert("系統提示", isPresented: errorBinding) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(model.loadError ?? "")
        }
        .safeAreaInset(edge: .top) {
            if let notice = model.usageNotice {
                UsageNoticeBanner(notice: notice) { model.dismissUsageNotice() }
                    .padding(.horizontal)
            }
        }
        .onAppear { model.beginForegroundUsage() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.beginForegroundUsage() }
            else { model.endForegroundUsage() }
        }
        .onReceive(usageTimer) { date in
            if scenePhase == .active { model.updateForegroundUsage(now: date) }
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

            NavigationStack { PracticeHubView() }
            .tabItem {
                Label("修行", systemImage: "figure.mind.and.body")
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
        case .seal: DailySealSessionView()
        case .journey: JourneyView()
        case .flash: FlashcardView()
        case .daily: JourneyTrialView(chapter: nil, dailyCount: 12)
        case .battle: BattleView()
        case .classroom: ClassroomView()
        case .parent: ParentGuideView()
        case .challenge: ChallengeView()
        case .practice: PracticeHubView()
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

private struct ParentExperienceModifier: ViewModifier {
    @AppStorage("parent-effects-enabled") private var effectsEnabled = true

    func body(content: Content) -> some View {
        content.transaction { transaction in
            if !effectsEnabled { transaction.disablesAnimations = true }
        }
    }
}

private struct UsageNoticeBanner: View {
    let notice: AppModel.UsageNotice
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notice == .warning ? "hourglass" : "moon.stars.fill")
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(notice == .warning ? "墨將乾" : "墨乾時刻").font(.headline)
                Text(notice == .warning ? "已學習十五分鐘，約五分鐘後收尾。" : "完成手上的字後，今天就安心收卷。")
                    .font(.subheadline)
            }
            Spacer()
            Button("知道了", action: dismiss).buttonStyle(.bordered)
        }
        .padding()
        .foregroundStyle(.primary)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cinnabar, lineWidth: 2) }
        .accessibilityElement(children: .contain)
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
