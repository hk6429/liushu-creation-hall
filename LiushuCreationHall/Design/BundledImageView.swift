import SwiftUI
import UIKit

struct BundledImageView: View {
    let resourceName: String
    var contentMode: ContentMode = .fit

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ContentUnavailableView(
                    "圖像暫無法載入",
                    systemImage: "photo"
                )
            }
        }
    }

    private func loadImage() -> UIImage? {
        let extensions = ["webp", "png", "jpg"]
        for fileExtension in extensions {
            let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: fileExtension,
                subdirectory: "ImportedImages"
            ) ?? Bundle.main.url(forResource: resourceName, withExtension: fileExtension)
            if let url, let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        return nil
    }
}
