import SwiftUI

struct LearningLibraryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection: LibraryShelf = .concept

    private var sections: [LessonSection] {
        guard let library = model.learningLibrary else { return [] }
        return selection == .concept ? library.concept : library.story
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Picker("閱讀內容", selection: $selection) {
                    ForEach(LibraryShelf.allCases) { shelf in
                        Text(shelf.rawValue).tag(shelf)
                    }
                }
                .pickerStyle(.segmented)

                if sections.isEmpty {
                    ContentUnavailableView(
                        "教材準備中",
                        systemImage: "books.vertical"
                    )
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(sections) { section in
                            NavigationLink {
                                LessonDetailView(section: section)
                            } label: {
                                LessonRow(section: section)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle("六書導讀")
    }
}

private enum LibraryShelf: String, CaseIterable, Identifiable {
    case concept = "概念導讀"
    case story = "造字故事"
    var id: String { rawValue }
}

private struct LessonRow: View {
    let section: LessonSection

    var body: some View {
        HStack(spacing: 16) {
            if let imageName = section.imageName {
                BundledImageView(resourceName: imageName, contentMode: .fill)
                    .frame(width: 112, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "text.book.closed.fill")
                    .font(.title)
                    .foregroundStyle(AppTheme.cinnabar)
                    .frame(width: 72)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(section.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(section.body)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityHint("點入閱讀全文")
    }
}

private struct LessonDetailView: View {
    let section: LessonSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let imageName = section.imageName {
                    BundledImageView(resourceName: imageName)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .accessibilityLabel("\(section.title)教學情境圖")
                }
                Text(section.body)
                    .font(.body)
                    .lineSpacing(7)
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(InkBackground())
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
