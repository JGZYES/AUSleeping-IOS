import SwiftUI

@main
struct AreYouSleepingApp: App {
    @StateObject private var store = Store.shared
    @StateObject private var stm = ScreenTimeManager.shared

    var body: some Scene {
        WindowGroup {
            if store.agreed {
                ContentView()
                    .environmentObject(store)
                    .preferredColorScheme(store.darkMode ? .dark : .light)
                    .onAppear {
                        BedtimeReminder.requestPermission()
                        BedtimeReminder.schedule(store: store)
                        // 请求屏幕时间权限（用于应用屏蔽）
                        Task {
                            await stm.requestAuthorization()
                        }
                    }
            } else {
                AgreementView()
                    .environmentObject(store)
            }
        }
    }
}
