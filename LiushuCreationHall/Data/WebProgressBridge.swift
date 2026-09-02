import Foundation

enum WebProgressBridge {
    static func export(_ progress: LearningProgress) throws -> Data {
        let iso = ISO8601DateFormatter()
        let cards = progress.cards.mapValues { card in
            ["box": card.box, "due": card.dueDay, "seen": card.seen, "right": card.right, "wrong": card.wrong, "streak": card.streak]
        }
        let byCat = progress.byCategory.mapValues { ["r": $0.right, "w": $0.wrong] }
        var byMode: [String: [String: Int]] = [:]
        for (mode, score) in progress.byMode {
            let webMode = mode == .journey ? "chapter_trial" : mode.rawValue
            guard mode != .flash else { continue }
            byMode[webMode] = ["r": score.right, "w": score.wrong]
        }
        let completed = Dictionary(uniqueKeysWithValues: progress.journey.completed.map { (String($0.key), iso.string(from: $0.value)) })
        let read = Dictionary(uniqueKeysWithValues: progress.journey.read.map { (String($0.key), iso.string(from: $0.value)) })
        let days = progress.days.mapValues { day in
            ["flash": day.flash, "quiz": day.quiz, "battle": day.battle, "total": day.total, "effective": day.effective]
        }
        let daily = progress.dailyChallenges.mapValues { result -> [String: Any] in
            let first: Any = result.first.map { $0 as Any } ?? NSNull()
            return ["attempts": result.attempts, "first": first, "best": result.best, "total": result.total]
        }
        let evidence = progress.skillEvidence.mapValues { value -> [String: Any] in
            let skill: [String: Any] = [
                "objectiveRight": value.objectiveRight, "objectiveWrong": value.objectiveWrong,
                "distinctDays": Array(value.distinctDays).sorted(), "delayedPasses": value.delayedPasses,
                "rationalePasses": value.rationalePasses,
                "unpromptedRationalePasses": value.unpromptedRationalePasses,
                "lastCorrectAt": value.lastCorrectAt.map { iso.string(from: $0) } as Any,
                "lastCorrectDay": value.lastCorrectDay as Any,
                "lastCorrectContext": value.lastCorrectContext as Any
            ]
            let empty: [String: Any] = [
                "objectiveRight": 0, "objectiveWrong": 0, "distinctDays": [],
                "delayedPasses": 0, "rationalePasses": 0, "unpromptedRationalePasses": 0,
                "lastCorrectAt": NSNull(), "lastCorrectDay": NSNull(), "lastCorrectContext": NSNull()
            ]
            let usage = value.category == CreationMethod.derivative.rawValue || value.category == CreationMethod.phoneticLoan.rawValue
            return usage ? ["formation": empty, "usage": skill] : ["formation": skill, "usage": empty]
        }
        let completedAt: Any = progress.onboardingStep >= 3 ? iso.string(from: .now) : NSNull()
        let pendingChapter: Any = progress.journey.pendingChapter.map { $0 as Any } ?? NSNull()
        var object: [String: Any] = [
            "schemaVersion": 4,
            "created": Int((progress.lastPlayedAt ?? .now).timeIntervalSince1970 * 1000),
            "cards": cards,
            "quiz": ["answered": progress.totalAttempts, "right": progress.totalCorrect, "byCat": byCat, "byMode": byMode, "recent": []],
            "battle": ["beaten": progress.battle.beaten, "losses": progress.battle.losses, "best": progress.battle.best],
            "days": days,
            "activity": ["days": days],
            "onboarding": ["step": progress.onboardingStep, "completedAt": completedAt, "skipped": false],
            "badges": progress.badges.mapValues { iso.string(from: $0) },
            "sessions": webSessions(progress),
            "dailyChallenges": daily,
            "skillEvidence": evidence,
            "recovery": [:],
            "journey": ["chapter": progress.journey.currentChapter, "completed": completed, "read": read, "pendingChapter": pendingChapter, "lastVisit": NSNull(), "weeklyGoal": progress.journey.weeklyGoal],
            "classroom": ["sessions": progress.classroomSessions.map { session in
                ["promptId": session.promptID, "title": session.title, "groups": session.groups, "changed": session.changed,
                 "confidenceUp": session.confidenceUp, "initialCounts": session.initialCounts,
                 "revisedCounts": session.revisedCounts, "evidenceCounts": session.evidenceCounts,
                 "wrongToRight": session.wrongToRight ?? 0, "rightToWrong": session.rightToWrong ?? 0,
                 "calibratedConfidence": session.calibratedConfidence ?? 0,
                 "completedAt": iso.string(from: session.completedAt)] as [String: Any]
            }, "evidenceWall": progress.evidenceWall, "active": webActiveClassroom(progress.activeClassroom)],
            "eventIds": []
        ]
        let habitEncoder = JSONEncoder()
        habitEncoder.dateEncodingStrategy = .iso8601
        let habitData = try habitEncoder.encode(progress.habit)
        object["nativeHabit"] = try JSONSerialization.jsonObject(with: habitData)
        let abilityData = try habitEncoder.encode(progress.abilityHistory)
        object["nativeAbilityHistory"] = try JSONSerialization.jsonObject(with: abilityData)
        return try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }

    static func importWebBackup(_ data: Data) throws -> LearningProgress {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cardsObject = root["cards"] as? [String: Any],
              let quiz = root["quiz"] as? [String: Any] else {
            throw ProgressImportError.invalidData
        }
        var progress = LearningProgress.empty
        progress.schemaVersion = 4
        progress.totalAttempts = int(quiz["answered"])
        progress.totalCorrect = min(progress.totalAttempts, int(quiz["right"]))

        for (id, raw) in cardsObject.prefix(1000) {
            guard id.range(of: #"^[A-Za-z0-9_\-\u{3400}-\u{9FFF}]{1,64}$"#, options: .regularExpression) != nil,
                  let value = raw as? [String: Any] else { continue }
            progress.cards[id] = CardProgress(
                box: min(5, max(1, int(value["box"], fallback: 1))), dueDay: int(value["due"]),
                seen: int(value["seen"]), right: int(value["right"]), wrong: int(value["wrong"]), streak: int(value["streak"])
            )
        }
        progress.completedQuestionIDs = Set(progress.cards.filter { $0.value.seen > 0 }.map(\.key))

        if let byCat = quiz["byCat"] as? [String: Any] {
            for (category, raw) in byCat {
                guard CreationMethod(rawValue: category) != nil, let value = raw as? [String: Any] else { continue }
                progress.byCategory[category] = ScoreBucket(right: int(value["r"]), wrong: int(value["w"]))
            }
        }
        if let byMode = quiz["byMode"] as? [String: Any] {
            for (name, raw) in byMode {
                guard let value = raw as? [String: Any] else { continue }
                let mode: PracticeMode? = name == "chapter_trial" || name == "home_daily" ? .journey : PracticeMode(rawValue: name)
                if let mode { progress.byMode[mode] = ScoreBucket(right: int(value["r"]), wrong: int(value["w"])) }
            }
        }
        if let battle = root["battle"] as? [String: Any] {
            progress.battle.beaten = counts(battle["beaten"])
            progress.battle.losses = counts(battle["losses"])
            progress.battle.best = counts(battle["best"])
        }
        if let journey = root["journey"] as? [String: Any] {
            progress.journey.currentChapter = min(7, int(journey["chapter"]))
            progress.journey.pendingChapter = journey["pendingChapter"] is NSNull ? nil : min(7, int(journey["pendingChapter"]))
            progress.journey.weeklyGoal = min(7, max(1, int(journey["weeklyGoal"], fallback: 3)))
            progress.journey.completed = dateMap(journey["completed"])
            progress.journey.read = dateMap(journey["read"])
        }
        let sourceDays = ((root["activity"] as? [String: Any])?["days"] as? [String: Any]) ?? root["days"] as? [String: Any] ?? [:]
        for (key, raw) in sourceDays where key.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
            if let value = raw as? [String: Any] {
                progress.days[key] = DailyActivity(flash: int(value["flash"]), quiz: int(value["quiz"]), battle: int(value["battle"]), effective: int(value["effective"]))
            }
        }
        if let onboarding = root["onboarding"] as? [String: Any] { progress.onboardingStep = min(3, int(onboarding["step"])) }
        if let sessions = root["sessions"] as? [String: Any] {
            progress.quizSessions = int(sessions["quiz"])
            if let last = sessions["lastQuiz"] as? [String: Any] {
                progress.lastQuizScore = int(last["score"])
                progress.lastQuizTotal = int(last["total"])
            }
        }
        if let daily = root["dailyChallenges"] as? [String: Any] {
            for (key, raw) in daily where key.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil {
                guard let value = raw as? [String: Any] else { continue }
                let first = value["first"] is NSNull ? nil : int(value["first"])
                progress.dailyChallenges[key] = DailyChallengeResult(
                    attempts: int(value["attempts"]), first: first,
                    best: int(value["best"]), total: int(value["total"], fallback: 12)
                )
            }
        }
        if let rawEvidence = root["skillEvidence"] as? [String: Any] {
            for (id, raw) in rawEvidence.prefix(1000) {
                guard let axes = raw as? [String: Any] else { continue }
                let formation = skill(axes["formation"])
                let usage = skill(axes["usage"])
                let selected = formation.objectiveRight + formation.objectiveWrong >= usage.objectiveRight + usage.objectiveWrong ? formation : usage
                if selected.objectiveRight + selected.objectiveWrong > 0 { progress.skillEvidence[id] = selected }
            }
        }
        if let rawBadges = root["badges"] as? [String: Any] {
            let formatter = ISO8601DateFormatter()
            for (id, raw) in rawBadges.prefix(200) {
                if let text = raw as? String, let date = formatter.date(from: text) { progress.badges[id] = date }
            }
        }
        if let classroom = root["classroom"] as? [String: Any] {
            if let wall = classroom["evidenceWall"] { progress.evidenceWall = counts(wall) }
            if let sessions = classroom["sessions"] as? [[String: Any]] {
                progress.classroomSessions = sessions.suffix(20).compactMap(classroomSession)
            }
            if let active = classroom["active"] as? [String: Any], let promptID = active["promptId"] as? String {
                progress.activeClassroom = ActiveClassroomSession(
                    promptID: promptID, groups: int(active["groups"]), changed: int(active["changed"]),
                    confidenceUp: int(active["confidenceUp"]), initialCounts: counts(active["initialCounts"]),
                    revisedCounts: counts(active["revisedCounts"]), evidenceCounts: counts(active["evidenceCounts"]),
                    wrongToRight: int(active["wrongToRight"]), rightToWrong: int(active["rightToWrong"]),
                    calibratedConfidence: int(active["calibratedConfidence"])
                )
            }
        }
        if let rawHabit = root["nativeHabit"], JSONSerialization.isValidJSONObject(rawHabit) {
            let habitData = try JSONSerialization.data(withJSONObject: rawHabit)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let habit = try? decoder.decode(HabitProgress.self, from: habitData) {
                progress.habit = habit
            }
        }
        if let rawAbility = root["nativeAbilityHistory"], JSONSerialization.isValidJSONObject(rawAbility) {
            let data = try JSONSerialization.data(withJSONObject: rawAbility)
            progress.abilityHistory = (try? JSONDecoder().decode([String: AbilitySnapshot].self, from: data)) ?? [:]
        }
        return progress
    }

    private static func skill(_ raw: Any?) -> SkillEvidence {
        guard let value = raw as? [String: Any] else { return SkillEvidence() }
        let days = Set((value["distinctDays"] as? [String] ?? []).filter {
            $0.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
        }.suffix(30))
        let rawLastCorrect = value["lastCorrectAt"] as? String
        let lastCorrectAt = rawLastCorrect.flatMap(ISO8601DateFormatter().date)
        let lastCorrectDay = value["lastCorrectDay"] as? String
            ?? lastCorrectAt.map(LearningClock.dateKey)
            ?? rawLastCorrect.flatMap { text in
                text.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil ? nil : text
            }
        return SkillEvidence(
            objectiveRight: int(value["objectiveRight"]), objectiveWrong: int(value["objectiveWrong"]),
            distinctDays: days, delayedPasses: int(value["delayedPasses"]),
            rationalePasses: int(value["rationalePasses"]),
            unpromptedRationalePasses: int(value["unpromptedRationalePasses"]),
            lastCorrectDay: lastCorrectDay, lastCorrectAt: lastCorrectAt,
            lastCorrectContext: value["lastCorrectContext"] as? String
        )
    }

    private static func classroomSession(_ value: [String: Any]) -> ClassroomSession? {
        guard let promptID = value["promptId"] as? String else { return nil }
        let title: String = switch promptID {
        case "ben-xiu": "本與休：部件關係"
        case "mo-axis": "莫：構形與用字軸線"
        case "kao-lao": "考與老：同源互訓"
        default: "六書共學"
        }
        let completedAt = (value["completedAt"] as? String).flatMap(ISO8601DateFormatter().date) ?? .now
        return ClassroomSession(
            id: UUID(), promptID: promptID, title: title,
            groups: int(value["groups"]), changed: int(value["changed"]), confidenceUp: int(value["confidenceUp"]),
            initialCounts: counts(value["initialCounts"]), revisedCounts: counts(value["revisedCounts"]),
            evidenceCounts: counts(value["evidenceCounts"]), completedAt: completedAt,
            wrongToRight: int(value["wrongToRight"]), rightToWrong: int(value["rightToWrong"]),
            calibratedConfidence: int(value["calibratedConfidence"])
        )
    }

    private static func webActiveClassroom(_ active: ActiveClassroomSession?) -> Any {
        guard let active else { return NSNull() }
        return [
            "promptId": active.promptID, "groups": active.groups, "changed": active.changed,
            "confidenceUp": active.confidenceUp, "initialCounts": active.initialCounts,
            "revisedCounts": active.revisedCounts, "evidenceCounts": active.evidenceCounts,
            "wrongToRight": active.wrongToRight ?? 0, "rightToWrong": active.rightToWrong ?? 0,
            "calibratedConfidence": active.calibratedConfidence ?? 0
        ] as [String: Any]
    }

    private static func webSessions(_ progress: LearningProgress) -> [String: Any] {
        var sessions: [String: Any] = [
            "quiz": progress.quizSessions,
            "flash": 0,
            "battle": progress.battle.beaten.values.reduce(0, +) + progress.battle.losses.values.reduce(0, +),
            "home_daily": progress.dailyChallenges.values.reduce(0) { $0 + $1.attempts },
            "chapter_trial": progress.journey.completed.count,
            "bestQuiz": progress.lastQuizScore ?? 0
        ]
        if let score = progress.lastQuizScore, let total = progress.lastQuizTotal {
            sessions["lastQuiz"] = ["score": score, "total": total, "at": NSNull()] as [String: Any]
        }
        return sessions
    }

    private static func int(_ value: Any?, fallback: Int = 0) -> Int {
        guard let number = value as? NSNumber else { return fallback }
        return max(0, min(1_000_000, number.intValue))
    }

    private static func counts(_ raw: Any?) -> [String: Int] {
        guard let values = raw as? [String: Any] else { return [:] }
        return Dictionary(uniqueKeysWithValues: values.prefix(1000).map { ($0.key, int($0.value)) })
    }

    private static func dateMap(_ raw: Any?) -> [Int: Date] {
        guard let values = raw as? [String: Any] else { return [:] }
        let formatter = ISO8601DateFormatter()
        return Dictionary(uniqueKeysWithValues: values.compactMap { key, value in
            guard let index = Int(key), let text = value as? String, let date = formatter.date(from: text) else { return nil }
            return (index, date)
        })
    }
}
