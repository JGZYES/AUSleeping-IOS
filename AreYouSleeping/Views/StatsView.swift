import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: Store

    private var records: [SleepRecord] { store.recentRecords(7) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // KPI 卡片
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatKpiCard(title: "平均睡眠", value: avgHours, unit: "小时", color: .blue)
                    StatKpiCard(title: "连续达标", value: "\(streakDays)", unit: "天", color: .green)
                    StatKpiCard(title: "准时入睡", value: "\(onTimeCount)/\(max(records.count, 1))", unit: "晚", color: .orange)
                    StatKpiCard(title: "达标率", value: String(format: "%.0f%%", goalRate * 100), unit: "", color: .purple)
                }

                // 最近记录
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("最近 7 晚")
                            .font(.headline)
                        Spacer()
                    }
                    if records.isEmpty {
                        Text("暂无睡眠记录")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .glassCard()
                    } else {
                        ForEach(records) { rec in
                            RecordRow(rec: rec)
                        }
                    }
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("统计").font(.headline)
            }
        }
    }

    private var avgHours: String {
        guard !records.isEmpty else { return "-" }
        return String(format: "%.1f", records.map(\.sleepHours).reduce(0, +) / Double(records.count))
    }

    private var goalRate: Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.filter { $0.sleepHours >= 7 }.count) / Double(records.count)
    }

    private var streakDays: Int {
        var count = 0
        for r in records {
            if r.sleepHours >= 7 { count += 1 } else { break }
        }
        return count
    }

    private var onTimeCount: Int {
        records.filter { $0.bedMinutes <= store.bedtimeMinutes + 30 }.count
    }
}

struct StatKpiCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title2).bold().foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard(radius: 14)
    }
}

struct RecordRow: View {
    let rec: SleepRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rec.nightDate).font(.subheadline).bold()
                Text("\(TimeUtil.fmt(rec.bedMinutes)) → \(TimeUtil.fmt(rec.wakeMinutes))")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "%.1f 小时", rec.sleepHours))
                .font(.headline)
                .foregroundColor(rec.sleepHours >= 7 ? .green : .orange)
        }
        .padding()
        .glassCard(radius: 14)
    }
}
