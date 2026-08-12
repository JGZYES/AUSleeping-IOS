import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [Color.white, Color(red: 0.84, green: 0.84, blue: 0.87)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

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
        }
    }
}
