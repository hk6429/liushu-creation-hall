import SwiftUI

struct ClassroomView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("課堂共學").font(.largeTitle.bold())
                Text("先答鎖定，再看理由，最後修正。不比快、不排名、不記姓名；只保存匿名彙整。")
                ForEach(ClassroomPrompt.all) { prompt in
                    NavigationLink {
                        ClassroomSessionView(prompt: prompt)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prompt.title).font(.headline)
                            Text(prompt.question).font(.subheadline)
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("classroom-prompt-\(prompt.id)")
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("匿名證據牆").font(.title2.bold())
                        Spacer()
                        Button("清空", role: .destructive) { model.clearEvidenceWall() }
                    }
                    if model.progress.evidenceWall.isEmpty {
                        Text("尚未累積課堂證據。" ).foregroundStyle(.primary)
                    } else {
                        ForEach(ClassroomPrompt.evidenceOptions, id: \.self) { item in
                            HStack { Text(item); Spacer(); Text("\(model.progress.evidenceWall[item, default: 0]) 次").bold() }
                        }
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding()
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("課堂共學")
    }
}

private struct ClassroomSessionView: View {
    @EnvironmentObject private var model: AppModel
    let prompt: ClassroomPrompt
    @State private var phase: Phase = .initial
    @State private var initial = ""
    @State private var initialConfidence = ClassroomPrompt.confidenceOptions[0]
    @State private var revised = ""
    @State private var revisedConfidence = ClassroomPrompt.confidenceOptions[0]
    @State private var evidence = ""
    @State private var groups = 0
    @State private var changed = 0
    @State private var confidenceUp = 0
    @State private var initialCounts: [String: Int] = [:]
    @State private var revisedCounts: [String: Int] = [:]
    @State private var evidenceCounts: [String: Int] = [:]
    @State private var wrongToRight = 0
    @State private var rightToWrong = 0
    @State private var calibratedConfidence = 0

    enum Phase { case initial, discuss, revise, reveal, collected, summary }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("第 \(groups + 1) 組").font(.headline).foregroundStyle(AppTheme.cinnabar)
                switch phase {
                case .initial: initialStep
                case .discuss: discussStep
                case .revise: revisionStep
                case .reveal: revealStep
                case .collected: collectedStep
                case .summary: summaryStep
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle(prompt.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: restoreActiveSession)
    }

    private var initialStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("階段 1／3・第一次答案").font(.title2.bold())
            Text(prompt.question).font(.title3)
            Picker("第一次答案", selection: $initial) {
                Text("請選擇").tag("")
                ForEach(prompt.options, id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.inline)
            Picker("第一次信心", selection: $initialConfidence) {
                ForEach(ClassroomPrompt.confidenceOptions, id: \.self) { Text($0).tag($0) }
            }
            Button("鎖定第一次答案") { phase = .discuss }
                .buttonStyle(.borderedProminent).disabled(initial.isEmpty)
        }
        .cardStyle()
    }

    private var discussStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("階段 2／3・比較理由").font(.title2.bold())
            Text("第一次答案已鎖定為「\(initial)」。先看匿名初答分布，再由小組提出可檢驗的證據；專家理由會在第二次作答後才揭示。")
            Text("目前匿名初答").font(.headline)
            counts(initialCounts.merging([initial: 1], uniquingKeysWith: +))
            Button("討論完成，進入第二次作答") { revised = initial; phase = .revise }
                .buttonStyle(.borderedProminent)
        }
        .cardStyle()
    }

    private var revisionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("階段 3／3・討論後再答").font(.title2.bold())
            Text(prompt.question).font(.title3)
            Picker("最關鍵的證據", selection: $evidence) {
                Text("請選擇").tag("")
                ForEach(ClassroomPrompt.evidenceOptions, id: \.self) { Text($0).tag($0) }
            }
            Picker("第二次答案", selection: $revised) {
                ForEach(prompt.options, id: \.self) { Text($0).tag($0) }
            }
            Picker("第二次信心", selection: $revisedConfidence) {
                ForEach(ClassroomPrompt.confidenceOptions, id: \.self) { Text($0).tag($0) }
            }
            Button("匿名送出修正版") { commitGroup() }
                .buttonStyle(.borderedProminent)
                .disabled(revised.isEmpty || evidence.isEmpty)
        }
        .cardStyle()
    }

    private var revealStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("二答已鎖定・核對專家理由").font(.title2.bold())
            Text(prompt.reason)
                .padding().background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 14))
            Text(revised == prompt.answer ? "第二次答案符合證據。" : "第二次答案仍可再比較；彙整只記匿名結果。")
                .font(.headline)
            Button("完成本組核對") { phase = .collected }
                .buttonStyle(.borderedProminent)
        }
        .cardStyle()
    }

    private var collectedStep: some View {
        VStack(spacing: 14) {
            Text("第 \(groups) 組已匿名彙整").font(.title2.bold())
            Text("個別答案不會保存，只保留全班分布、信心變化與證據次數。")
            HStack {
                Button("下一組作答") { resetGroup() }.buttonStyle(.borderedProminent)
                Button("看全班彙整") { saveSummary() }.buttonStyle(.bordered)
            }
        }
        .cardStyle()
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("匿名全班彙整").font(.largeTitle.bold())
            Text("共 \(groups) 組；錯轉對 \(wrongToRight) 組、對轉錯 \(rightToWrong) 組、答對且高信心 \(calibratedConfidence) 組。")
            Text("另有 \(changed) 組更改答案、\(confidenceUp) 組提高信心；變動本身不等於學會。")
            Text("第一次答案").font(.headline)
            counts(initialCounts)
            Text("討論後答案").font(.headline)
            counts(revisedCounts)
            Text("採用的證據").font(.headline)
            counts(evidenceCounts)
            Text(prompt.reason).padding().background(AppTheme.parchment, in: RoundedRectangle(cornerRadius: 14))
        }
        .cardStyle()
    }

    private func counts(_ values: [String: Int]) -> some View {
        VStack { ForEach(values.keys.sorted(), id: \.self) { key in HStack { Text(key); Spacer(); Text("\(values[key, default: 0]) 組").bold() } } }
    }

    private func commitGroup() {
        groups += 1
        initialCounts[initial, default: 0] += 1
        revisedCounts[revised, default: 0] += 1
        evidenceCounts[evidence, default: 0] += 1
        if initial != revised { changed += 1 }
        if initial != prompt.answer, revised == prompt.answer { wrongToRight += 1 }
        if initial == prompt.answer, revised != prompt.answer { rightToWrong += 1 }
        if revised == prompt.answer, revisedConfidence == ClassroomPrompt.confidenceOptions.last { calibratedConfidence += 1 }
        if ClassroomPrompt.confidenceOptions.firstIndex(of: revisedConfidence)! > ClassroomPrompt.confidenceOptions.firstIndex(of: initialConfidence)! { confidenceUp += 1 }
        model.saveActiveClassroom(ActiveClassroomSession(
            promptID: prompt.id, groups: groups, changed: changed, confidenceUp: confidenceUp,
            initialCounts: initialCounts, revisedCounts: revisedCounts, evidenceCounts: evidenceCounts,
            wrongToRight: wrongToRight, rightToWrong: rightToWrong,
            calibratedConfidence: calibratedConfidence
        ))
        phase = .reveal
    }

    private func resetGroup() {
        initial = ""; revised = ""; initialConfidence = ClassroomPrompt.confidenceOptions[0]
        revisedConfidence = ClassroomPrompt.confidenceOptions[0]; evidence = ""
        phase = .initial
    }

    private func saveSummary() {
        model.addClassroomSession(ClassroomSession(
            id: UUID(), promptID: prompt.id, title: prompt.title, groups: groups, changed: changed,
            confidenceUp: confidenceUp, initialCounts: initialCounts, revisedCounts: revisedCounts,
            evidenceCounts: evidenceCounts, completedAt: .now,
            wrongToRight: wrongToRight, rightToWrong: rightToWrong,
            calibratedConfidence: calibratedConfidence
        ))
        phase = .summary
    }

    private func restoreActiveSession() {
        guard let active = model.progress.activeClassroom, active.promptID == prompt.id, groups == 0 else { return }
        groups = active.groups
        changed = active.changed
        confidenceUp = active.confidenceUp
        initialCounts = active.initialCounts
        revisedCounts = active.revisedCounts
        evidenceCounts = active.evidenceCounts
        wrongToRight = active.wrongToRight ?? 0
        rightToWrong = active.rightToWrong ?? 0
        calibratedConfidence = active.calibratedConfidence ?? 0
        if groups > 0 { phase = .collected }
    }
}

private extension View {
    func cardStyle() -> some View {
        padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }
}
