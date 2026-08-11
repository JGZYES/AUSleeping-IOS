import Foundation

/// 睡眠记录
struct SleepRecord: Identifiable, Codable {
    var id: String { nightDate }
    let nightDate: String      // "2026-08-10"
    let bedMinutes: Int        // 入睡分钟数
    let wakeMinutes: Int       // 起床分钟数
    let sleepHours: Double     // 睡眠时长

    /// 序列化：nightDate|bedMinutes|wakeMinutes|sleepHours
    func serialize() -> String {
        String(format: "%@|%d|%d|%.2f", nightDate, bedMinutes, wakeMinutes, sleepHours)
    }

    static func parse(_ line: String) -> SleepRecord? {
        let parts = line.components(separatedBy: "|")
        guard parts.count == 4,
              let bed = Int(parts[1]),
              let wake = Int(parts[2]),
              let hours = Double(parts[3]) else { return nil }
        return SleepRecord(nightDate: parts[0], bedMinutes: bed, wakeMinutes: wake, sleepHours: hours)
    }
}
