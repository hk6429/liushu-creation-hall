import Foundation

protocol ProgressStoring {
    func load() throws -> LearningProgress
    func save(_ progress: LearningProgress) throws
}

struct FileProgressStore: ProgressStoring {
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0].appendingPathComponent("LiushuCreationHall", isDirectory: true)
            self.fileURL = directory.appendingPathComponent("progress.json")
        }
    }

    func load() throws -> LearningProgress {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: fileURL)
        if let progress = try? decoder.decode(LearningProgress.self, from: data) {
            return progress
        }
        let legacyDecoder = JSONDecoder()
        return try legacyDecoder.decode(LearningProgress.self, from: data)
    }

    func save(_ progress: LearningProgress) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(progress).write(to: fileURL, options: .atomic)
    }
}
