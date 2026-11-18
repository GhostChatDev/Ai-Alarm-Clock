import SwiftUI
import UserNotifications

@main
struct ReadyByEightApp: App {
    @State private var store = AppStore()
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .task { await store.refresh() }
        }
    }
}
