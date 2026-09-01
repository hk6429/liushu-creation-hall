import SwiftUI

@main
struct LiushuCreationHallApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(AppTheme.cinnabar)
        }
    }
}
