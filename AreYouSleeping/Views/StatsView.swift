import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: Store

    private var records: [SleepRecord] { store.recentRecords(7) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // KPI 卡片
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        kpiCard(title: "平均睡眠", value: avgHours, unit: "小时", color: .blue)
                        kpiCard(title: "连续达标", value: "\(streakDays)", unit: "天", color: .green)
                        kpiCard(title: "准时入睡", value: "\(onTimeCount)/\(max(records.count, 1))", unit: "晚", color: .orange)
                        kpiCard(title: "达标率", value: String(format: "%.0f%%", goalRate * 100), unit: "", color: .purple)
                    }

                    // 最近记录
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近 7 晚").font(.headline).padding(.horizontal)
                        if records.isEmpty {
                            Text("暂无睡眠记录").foregroundColor(.secondary).padding()
                        } else {
                            ForEach(records) { rec in
                                recordRow(rec)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("统计")
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

    @ViewBuilder
    private func kpiCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title2).bold().foregroundColor(color)
                if !unit.isEmpty { Text(unit).font(.caption).foregroundColor(.secondary) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func recordRow(_ rec: SleepRecord) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(rec.nightDate).font(.subheadline).bold()
                Text("\(TimeUtil.fmt(rec.bedMinutes)) → \(TimeUtil.fmt(rec.wakeMinutes))")
                        .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(String(format: "%.1f 小时", rec.sleepHours))
                .font(.headline).foregroundColor(rec.sleepHours >= 7 ? .green : .orange)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
