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
        return try JSONDecoder().decode(
            LearningProgress.self,
            from: Data(contentsOf: fileURL)
        )
    }

    func save(_ progress: LearningProgress) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(progress).write(to: fileURL, options: .atomic)
    }
}
