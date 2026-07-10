import SwiftUI

@main
struct BabyFoodDiaryApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// Task 1 placeholder. Task 3 replaces this with the full tab-based root view.
struct RootView: View {
    var body: some View {
        Text("泡泡的辅食日记")
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
    }
}
