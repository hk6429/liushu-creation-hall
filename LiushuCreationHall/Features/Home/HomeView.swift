import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DailySealCard()
                hero
                onboarding
                progressSection
                trainingGrounds
                methodGrid
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("六書造字堂")
    }

    @ViewBuilder
    private var onboarding: some View {
        if model.progress.onboardingStep < 3 {
            VStack(alignment: .leading, spacing: 10) {
                Text("三步入門 \(model.progress.onboardingStep + 1)／3").font(.title2.bold())
                Text(["先看懂修行路線", "完成一張真實閃卡", "答一題自測完成入門"][model.progress.onboardingStep])
                HStack {
                    if model.progress.onboardingStep == 0 {
                        Button("看懂了") { model.advanceOnboarding() }.buttonStyle(.borderedProminent)
                    } else if model.progress.onboardingStep == 1 {
                        NavigationLink("去翻閃卡") { FlashcardView() }.buttonStyle(.borderedProminent)
                    } else {
                        NavigationLink("去答一題") { ChallengeView() }.buttonStyle(.borderedProminent)
                    }
                    Button("先跳過") { model.skipOnboarding() }.buttonStyle(.bordered)
                }
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var hero: some View {
        HStack(spacing: 18) {
            Text("字")
                .font(.system(size: 56, weight: .black, design: .serif))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(AppTheme.cinnabar, in: RoundedRectangle(cornerRadius: 24))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text("看懂漢字，像看見古人留下的密碼。")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text("從字形、字音到字義，一起走進六書的世界。")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的學習卷")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 12) {
                ProgressTile(
                    title: "已探索",
                    value: "\(model.progress.completedQuestionIDs.count) 題",
                    symbol: "checkmark.seal.fill"
                )
                ProgressTile(
                    title: "正確率",
                    value: model.progress.totalAttempts == 0
                        ? "尚未開始"
                        : model.progress.accuracy.formatted(.percent.precision(.fractionLength(0))),
                    symbol: "scope"
                )
                ProgressTile(
                    title: "最佳連續",
                    value: "\(model.progress.bestStreak) 題",
                    symbol: "flame.fill"
                )
            }
        }
    }

    private var methodGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("六書六扇門")
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(CreationMethod.allCases) { method in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: method.systemImage)
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.color(for: method))
                        Text(method.rawValue)
                            .font(.headline)
                        Text(method.shortDefinition)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppTheme.color(for: method), lineWidth: 2)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var trainingGrounds: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完整練功場").font(.title2.bold())
            LazyVGrid(columns: columns, spacing: 14) {
                destination("八卷旅程", "map.fill", "故事、短試煉與每日五題") { JourneyView() }
                destination("閃卡複習", "rectangle.on.rectangle.angled", "Leitner 五盒間隔複習") { FlashcardView() }
                destination("每日字陣", "calendar", "每日固定 12 題挑戰") { JourneyTrialView(chapter: nil, dailyCount: 12) }
                destination("大師對戰", "figure.fencing", "八位文字學大師 PvE") { BattleView() }
                destination("課堂共學", "person.3.fill", "匿名初答、討論與修正") { ClassroomView() }
                destination("家長陪學", "figure.2.and.child.holdinghands", "10 分鐘低壓力陪學") { ParentGuideView() }
            }
        }
    }

    private func destination<Destination: View>(
        _ title: String,
        _ symbol: String,
        _ subtitle: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol).font(.title2).foregroundStyle(AppTheme.cinnabar)
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct ProgressTile: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(AppTheme.cinnabar)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption.bold())
                Text(value)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}
