import XCTest
@testable import LiushuCreationHall

final class QuizEngineTests: XCTestCase {
    func testCorrectAnswerProducesCorrectFeedback() {
        let question = CharacterQuestion(
            id: "test-sun",
            display: "日",
            prompt: "這個字屬於哪一類？",
            correctMethod: .pictograph,
            clue: "像圖畫",
            explanation: "日像太陽。"
        )

        let feedback = QuizEngine.evaluate(question: question, answer: .pictograph)

        XCTAssertTrue(feedback.isCorrect)
        XCTAssertEqual(feedback.correctMethod, .pictograph)
    }

    func testWrongAnswerResetsCurrentStreakButKeepsBestStreak() {
        var progress = LearningProgress.empty
        let correct = AnswerFeedback(
            questionID: "1",
            selectedMethod: .pictograph,
            correctMethod: .pictograph,
            explanation: ""
        )
        let wrong = AnswerFeedback(
            questionID: "2",
            selectedMethod: .indicative,
            correctMethod: .associative,
            explanation: ""
        )

        progress.record(correct)
        progress.record(correct)
        progress.record(wrong)

        XCTAssertEqual(progress.totalAttempts, 3)
        XCTAssertEqual(progress.totalCorrect, 2)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.bestStreak, 2)
    }

    func testFileProgressStoreRestoresSavedProgress() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("progress.json")
        let store = FileProgressStore(fileURL: fileURL)
        var progress = LearningProgress.empty
        progress.record(
            AnswerFeedback(
                questionID: "saved-question",
                selectedMethod: .associative,
                correctMethod: .associative,
                explanation: ""
            )
        )

        try store.save(progress)
        let restored = try store.load()

        XCTAssertEqual(restored.totalAttempts, 1)
        XCTAssertEqual(restored.completedQuestionIDs, ["saved-question"])
    }

    func testLeitnerGradesMoveAndResetCards() {
        var progress = LearningProgress.empty
        progress.gradeCard(id: "c0001", grade: 2)
        XCTAssertEqual(progress.cards["c0001"]?.box, 2)
        XCTAssertEqual(progress.cards["c0001"]?.right, 1)

        progress.gradeCard(id: "c0001", grade: 0)
        XCTAssertEqual(progress.cards["c0001"]?.box, 1)
        XCTAssertEqual(progress.cards["c0001"]?.wrong, 1)
    }

    func testJourneyNeedsTwoOfThreeToUnlockNextChapter() {
        var progress = LearningProgress.empty
        XCTAssertFalse(progress.completeJourney(chapter: 0, score: 1, total: 3))
        XCTAssertEqual(progress.journey.currentChapter, 0)
        XCTAssertEqual(progress.journey.pendingChapter, 0)

        XCTAssertTrue(progress.completeJourney(chapter: 0, score: 2, total: 3))
        XCTAssertEqual(progress.journey.currentChapter, 1)
        XCTAssertNotNil(progress.journey.completed[0])
    }

    func testBattleTracksWinsLossesAndBestScore() {
        var progress = LearningProgress.empty
        progress.recordBattle(masterID: "wangyirong", win: false, score: 4)
        progress.recordBattle(masterID: "wangyirong", win: true, score: 8)
        progress.recordBattle(masterID: "wangyirong", win: true, score: 7)

        XCTAssertEqual(progress.battle.losses["wangyirong"], 1)
        XCTAssertEqual(progress.battle.beaten["wangyirong"], 2)
        XCTAssertEqual(progress.battle.best["wangyirong"], 8)
    }

    func testDailyQuestionsAreStableForSameDate() {
        let entries = CreationMethod.allCases.enumerated().map { index, method in
            CharacterEntry(
                id: "c\(index)", char: "字\(index)", zhuyin: "ㄗˋ", category: method.rawValue,
                classificationScope: "構形方式", sub: nil, subScope: nil, level: "基礎",
                explain: "說明", shuowen: "", shuowenStatus: "待核", disputed: false,
                disputeNote: "", formationCategory: method.rawValue, usageRelations: []
            )
        }
        let first = QuizSessionFactory.makeDailyQuestions(from: entries, dateKey: "2026-09-01", count: 6)
        let second = QuizSessionFactory.makeDailyQuestions(from: entries, dateKey: "2026-09-01", count: 6)
        XCTAssertEqual(first.map(\.id), second.map(\.id))
        XCTAssertEqual(Set(first.map(\.correctMethod)), Set(CreationMethod.allCases))
    }

    func testLegacyPhaseOneProgressStillDecodes() throws {
        let json = #"{"totalAttempts":2,"totalCorrect":1,"currentStreak":0,"bestStreak":1,"completedQuestionIDs":["c0001"],"lastPlayedAt":null}"#
        let decoded = try JSONDecoder().decode(LearningProgress.self, from: Data(json.utf8))
        XCTAssertEqual(decoded.totalAttempts, 2)
        XCTAssertTrue(decoded.cards.isEmpty)
        XCTAssertEqual(decoded.schemaVersion, 1)
    }

    func testFileStoreReadsLegacyNumericDate() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("progress.json")
        let json = #"{"totalAttempts":1,"totalCorrect":1,"currentStreak":1,"bestStreak":1,"completedQuestionIDs":["c0006"],"lastPlayedAt":809969557.345141}"#
        try Data(json.utf8).write(to: fileURL)

        let restored = try FileProgressStore(fileURL: fileURL).load()

        XCTAssertEqual(restored.totalAttempts, 1)
        XCTAssertNotNil(restored.lastPlayedAt)
    }

    func testWebCompatibleBackupRoundTripsCoreProgress() throws {
        var progress = LearningProgress.empty
        progress.gradeCard(id: "c0001", grade: 2)
        progress.recordBattle(masterID: "wangyirong", win: true, score: 8)
        let data = try WebProgressBridge.export(progress)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["quiz"])
        XCTAssertNotNil(object["cards"])
        XCTAssertEqual(object["schemaVersion"] as? Int, 3)

        let restored = try WebProgressBridge.importWebBackup(data)
        XCTAssertEqual(restored.cards["c0001"]?.box, 2)
        XCTAssertEqual(restored.battle.beaten["wangyirong"], 1)
    }

    func testMasteryRequiresEvidenceAndASecondLearningDay() {
        var progress = LearningProgress.empty
        let answer = AnswerFeedback(
            questionID: "c0001", selectedMethod: .pictograph,
            correctMethod: .pictograph, explanation: ""
        )
        let firstDay = Date(timeIntervalSince1970: 1_788_192_000)
        let secondDay = firstDay.addingTimeInterval(86_400)

        progress.record(answer, now: firstDay)
        progress.record(answer, now: firstDay)
        progress.recordRationale(questionID: "c0001", method: .pictograph, correct: true, now: firstDay)
        XCTAssertFalse(progress.masteredIDs.contains("c0001"))

        progress.record(answer, now: secondDay)
        XCTAssertTrue(progress.masteredIDs.contains("c0001"))
    }

    func testCategoryBadgeOnlyCountsMasteredCharactersInThatCategory() {
        var progress = LearningProgress.empty
        for index in 0..<5 {
            let id = "p\(index)"
            progress.completedQuestionIDs.insert(id)
            progress.skillEvidence[id] = SkillEvidence(
                category: CreationMethod.pictograph.rawValue,
                objectiveRight: 3, distinctDays: ["2026-08-31", "2026-09-01"],
                delayedPasses: 1, rationalePasses: 1
            )
        }
        progress.evaluateBadges()

        XCTAssertNotNil(progress.badges["cat-象形"])
        XCTAssertNil(progress.badges["cat-指事"])
    }

    func testQuizBadgesUseCompletedQuizSessionRatherThanCrossModeStreak() {
        var progress = LearningProgress.empty
        progress.currentStreak = 10
        progress.evaluateBadges()
        XCTAssertNil(progress.badges["first-quiz"])
        XCTAssertNil(progress.badges["perfect-ten"])

        progress.recordQuizSession(score: 10, total: 10)
        XCTAssertNotNil(progress.badges["first-quiz"])
        XCTAssertNotNil(progress.badges["perfect-ten"])
    }

    func testLegacyPhaseTwoProgressDecodesWithEmptyHabit() throws {
        let json = #"{"totalAttempts":4,"totalCorrect":3,"schemaVersion":2}"#
        let decoded = try JSONDecoder().decode(LearningProgress.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.totalAttempts, 4)
        XCTAssertTrue(decoded.habit.dailyRecords.isEmpty)
        XCTAssertNil(decoded.habit.anchor)
    }

    func testDailySealPlannerIsStableUniqueAndSkipsDisputedEntries() {
        let entries = makeHabitEntries() + [
            makeEntry(id: "disputed", method: .pictograph, disputed: true)
        ]
        let date = taipeiDate("2026-09-02")

        let first = DailySealPlanner.makePlan(characters: entries, progress: .empty, now: date)
        let second = DailySealPlanner.makePlan(characters: entries, progress: .empty, now: date)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.characterIDs.count, 5)
        XCTAssertEqual(Set(first.characterIDs).count, 5)
        XCTAssertFalse(first.characterIDs.contains("disputed"))
    }

    func testRecoveryThresholdsUseFullMissedDays() {
        var habit = HabitProgress()
        let lastDate = taipeiDate("2026-09-01")
        habit.dailyRecords["2026-09-01"] = completedSeal(dateKey: "2026-09-01", date: lastDate)

        XCTAssertEqual(habit.sealKind(now: taipeiDate("2026-09-04")), .normal)
        XCTAssertEqual(habit.sealKind(now: taipeiDate("2026-09-05")), .recoveryOne)
        XCTAssertEqual(habit.sealKind(now: taipeiDate("2026-09-09")), .recoveryThree)
    }

    func testWeeklySealCountsDistinctCompletedDatesOnly() {
        var habit = HabitProgress()
        for day in 1...3 {
            let key = "2026-09-0\(day)"
            habit.dailyRecords[key] = completedSeal(dateKey: key, date: taipeiDate(key))
        }
        habit.dailyRecords["unfinished"] = DailySealRecord(
            dateKey: "2026-09-04", plannedCharacterIDs: ["c1"], attemptedCharacterIDs: [],
            correctCharacterIDs: [], kind: .normal, startedAt: taipeiDate("2026-09-04")
        )

        XCTAssertEqual(habit.completedDaysThisWeek(now: taipeiDate("2026-09-03")), 3)
    }

    func testUsageClockWarnsStopsAndRollsOver() {
        var clock = UsageClockState(dateKey: "2026-09-02")
        let day = taipeiDate("2026-09-02")
        clock.addForegroundTime(899, now: day)
        XCTAssertFalse(clock.hasReachedWarning)
        clock.addForegroundTime(1, now: day)
        XCTAssertTrue(clock.hasReachedWarning)
        XCTAssertFalse(clock.hasReachedStop)
        clock.addForegroundTime(300, now: day)
        XCTAssertTrue(clock.hasReachedStop)
        XCTAssertEqual(clock.foregroundSeconds, 1_200)

        clock.rollOverIfNeeded(now: taipeiDate("2026-09-03"))
        XCTAssertEqual(clock.foregroundSeconds, 0)
        XCTAssertFalse(clock.didReachStop)
    }

    func testWebBackupRoundTripsNativeHabit() throws {
        var progress = LearningProgress.empty
        progress.habit.anchor = .afterSchool
        progress.habit.preferredCategory = .associative
        let date = taipeiDate("2026-09-02")
        progress.habit.dailyRecords["2026-09-02"] = completedSeal(dateKey: "2026-09-02", date: date)

        let data = try WebProgressBridge.export(progress)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(object["nativeHabit"])

        let restored = try WebProgressBridge.importWebBackup(data)
        XCTAssertEqual(restored.habit.anchor, .afterSchool)
        XCTAssertEqual(restored.habit.preferredCategory, .associative)
        XCTAssertTrue(restored.habit.dailyRecords["2026-09-02"]?.isComplete == true)
    }

    @MainActor
    func testWrongDailySealAnswerCountsAttemptOnceWithoutMastery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = AppModel(
            progressStore: FileProgressStore(fileURL: directory.appendingPathComponent("progress.json")),
            contentLoader: HabitTestContentLoader(entries: makeHabitEntries())
        )
        model.setStudyAnchor(.afterSchool)
        let now = taipeiDate("2026-09-02")
        let record = try XCTUnwrap(model.prepareDailySeal(now: now))
        let question = try XCTUnwrap(model.activeSealQuestions().first)
        let wrongMethod = CreationMethod.allCases.first { $0 != question.correctMethod }!

        let first = model.submitDailySealAnswer(question: question, answer: wrongMethod, now: now)
        let duplicate = model.submitDailySealAnswer(question: question, answer: wrongMethod, now: now)

        XCTAssertNotNil(first)
        XCTAssertNil(duplicate)
        XCTAssertEqual(model.progress.habit.dailyRecords[record.dateKey]?.attemptedCount, 1)
        XCTAssertEqual(model.progress.habit.dailyRecords[record.dateKey]?.correctCount, 0)
        XCTAssertEqual(model.progress.totalCorrect, 0)
        XCTAssertFalse(model.progress.masteredIDs.contains(question.id))
    }

    @MainActor
    func testFiveDistinctAttemptsCompleteSealEvenWhenWrong() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let model = AppModel(
            progressStore: FileProgressStore(fileURL: directory.appendingPathComponent("progress.json")),
            contentLoader: HabitTestContentLoader(entries: makeHabitEntries())
        )
        model.setStudyAnchor(.afterDinner)
        let now = taipeiDate("2026-09-02")
        let record = try XCTUnwrap(model.prepareDailySeal(now: now))
        let questions = model.activeSealQuestions()

        for question in questions {
            let wrongMethod = CreationMethod.allCases.first { $0 != question.correctMethod }!
            XCTAssertNotNil(model.submitDailySealAnswer(question: question, answer: wrongMethod, now: now))
        }

        let completed = try XCTUnwrap(model.progress.habit.dailyRecords[record.dateKey])
        XCTAssertTrue(completed.isComplete)
        XCTAssertEqual(completed.attemptedCount, 5)
        XCTAssertEqual(completed.correctCount, 0)
        XCTAssertEqual(model.progress.habit.completedDaysThisWeek(now: now), 1)
        XCTAssertEqual(model.progress.habit.sevenDay.completedStages, [1])
        XCTAssertTrue(model.progress.masteredIDs.isEmpty)
    }

    private func makeHabitEntries() -> [CharacterEntry] {
        CreationMethod.allCases.enumerated().flatMap { index, method in
            [
                makeEntry(id: "h\(index)a", method: method),
                makeEntry(id: "h\(index)b", method: method)
            ]
        }
    }

    private func makeEntry(id: String, method: CreationMethod, disputed: Bool = false) -> CharacterEntry {
        CharacterEntry(
            id: id, char: id, zhuyin: "ㄗˋ", category: method.rawValue,
            classificationScope: "構形方式", sub: nil, subScope: nil, level: "基礎",
            explain: "測試說明", shuowen: "", shuowenStatus: "待核", disputed: disputed,
            disputeNote: "", formationCategory: method.rawValue, usageRelations: []
        )
    }

    private func completedSeal(dateKey: String, date: Date) -> DailySealRecord {
        DailySealRecord(
            dateKey: dateKey, plannedCharacterIDs: ["c1"], attemptedCharacterIDs: ["c1"],
            correctCharacterIDs: ["c1"], kind: .recoveryOne, startedAt: date, completedAt: date
        )
    }

    private func taipeiDate(_ key: String) -> Date {
        LearningClock.date(from: key)!
    }
}

private struct HabitTestContentLoader: WebContentLoading {
    let entries: [CharacterEntry]

    func loadCharacters() throws -> [CharacterEntry] { entries }
    func loadLearningLibrary() throws -> LearningLibrary {
        LearningLibrary(
            schemaVersion: 1, sourceRepository: "tests", sourceVersion: "1", importedAt: "2026-09-02",
            concept: [LessonSection(id: "concept", title: "概念", body: "內容", imageName: nil)],
            story: [LessonSection(id: "story", title: "故事", body: "內容", imageName: nil)]
        )
    }
}
