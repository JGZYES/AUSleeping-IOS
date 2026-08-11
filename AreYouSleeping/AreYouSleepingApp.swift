import SwiftUI

@main
struct AreYouSleepingApp: App {
    @StateObject private var store = Store.shared

    var body: some Scene {
        WindowGroup {
            if store.agreed {
                ContentView()
                    .environmentObject(store)
                    .preferredColorScheme(store.darkMode ? .dark : .light)
                    .onAppear {
                        BedtimeReminder.requestPermission()
                        BedtimeReminder.schedule(store: store)
                    }
            } else {
                AgreementView()
                    .environmentObject(store)
            }
        }
    }
}
