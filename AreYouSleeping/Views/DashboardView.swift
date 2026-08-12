import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: Store
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 时钟 + 日期
                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                    Text(dateString)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top, 20)

                // 问候语
                Text(greeting)
                    .font(.title2)

                // 倒计时卡片
                VStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(countdownText)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassCard()

                // 就寝/起床时间卡片
                HStack(spacing: 12) {
                    infoCard(title: "就寝时间", value: TimeUtil.fmt(store.bedtimeMinutes), icon: "moon.fill")
                    infoCard(title: "起床时间", value: TimeUtil.fmt(store.waketimeMinutes), icon: "sunrise.fill")
                }

                // 监督状态
                HStack {
                    Image(systemName: store.supervisionEnabled ? "shield.checkered" : "shield.slash")
                        .foregroundColor(store.supervisionEnabled ? .green : .secondary)
                    Text(store.supervisionEnabled ? "监督运行中" : "监督已关闭")
                        .font(.subheadline)
                }

                // 入睡/起床按钮
                if store.isSleeping {
                    Button {
                        store.endSleep()
                    } label: {
                        Label("我起床了", systemImage: "sunrise.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                } else {
                    Button {
                        store.startSleep()
                    } label: {
                        Label("我要睡觉了", systemImage: "moon.zzz.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.indigo)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("睡了吗")
                    .font(.headline)
            }
        }
        .onReceive(timer) { t in now = t }
    }

    private var timeString: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: now)
    }

    private var dateString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy年M月d日 EEEE"; f.locale = Locale(identifier: "zh_CN")
        return f.string(from: now)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: now)
        switch h {
        case 0..<6: return "夜深了，好好休息"
        case 6..<12: return "早上好！新的一天开始了"
        case 12..<18: return "下午好，注意休息"
        default: return "晚上好，准备放松吧"
        }
    }

    private var statusTitle: String {
        if store.isSleeping { return "正在睡眠中" }
        let nowMin = TimeUtil.nowMinutes()
        if TimeUtil.inNightWindow(nowMin, bedtime: store.bedtimeMinutes, waketime: store.waketimeMinutes) {
            return "已到睡觉时间！"
        }
        return "距离睡觉还有"
    }

    private var countdownText: String {
        if store.isSleeping {
            let elapsed = Int((Date().timeIntervalSince1970 * 1000 - store.sleepStartMillis) / 3_600_000)
            return "已睡 \(elapsed) 小时"
        }
        let nowMin = TimeUtil.nowMinutes()
        var remain = store.bedtimeMinutes - nowMin
        if remain < 0 { remain += 24 * 60 }
        return "\(remain / 60) 小时 \(remain % 60) 分钟"
    }

    @ViewBuilder
    private func infoCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value).font(.title3).bold()
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard()
    }
}

// MARK: - 玻璃卡片 Modifier
extension View {
    func glassCard(radius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(.thinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
    }
}
