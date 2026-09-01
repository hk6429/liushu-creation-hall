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
}
