import Foundation

/// 时间工具：统一用"自 00:00 起的分钟数"
enum TimeUtil {
    /// 当前分钟数
    static func nowMinutes() -> Int {
        let cal = Calendar.current
        let h = cal.component(.hour, from: Date())
        let m = cal.component(.minute, from: Date())
        return h * 60 + m
    }

    /// 格式化为 "HH:mm"
    static func fmt(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// 是否在睡眠窗口内（处理跨午夜）
    static func inNightWindow(_ now: Int, bedtime: Int, waketime: Int) -> Bool {
        if bedtime < waketime {
            return now >= bedtime && now < waketime
        } else {
            return now >= bedtime || now < waketime
        }
    }

    /// 超出就寝时间的分钟数
    static func overdueMinutes(_ now: Int, bedtime: Int) -> Int {
        inNightWindow(now, bedtime: bedtime, waketime: bedtime + 1) ? now - bedtime : 0
    }

    /// Date → 分钟数
    static func minuteOfDay(_ date: Date) -> Int {
        let cal = Calendar.current
        return cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
    }

    /// 日期字符串 "yyyy-MM-dd"
    static func dateStr(_ date: Date, offsetDays: Int = 0) -> String {
        let cal = Calendar.current
        let d = cal.date(byAdding: .day, value: offsetDays, to: date) ?? date
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }
}
