import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var selectedTab = 0
    @State private var settingsRefresh = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("仪表盘")
                }
                .tag(0)

            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(2)
        }
        .tint(.blue)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
