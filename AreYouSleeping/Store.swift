import Foundation

/// 全局数据中心（基于 UserDefaults），等价于 Android SharedPreferences
@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    // MARK: - 设置项
    @Published var bedtimeMinutes: Int = 23 * 60
    @Published var waketimeMinutes: Int = 7 * 60
    @Published var supervisionEnabled: Bool = true
    @Published var darkMode: Bool = false
    @Published var leadMinutes: Int = 30
    @Published var nagMinutes: Int = 10
    @Published var navStyle: Int = 0          // 0=默认, 1=无边框
    @Published var fontScale: Double = 1.0    // 0.85~1.3
    @Published var fontStyle: Int = 0         // 0=默认, 1=圆体, 2=等宽
    @Published var cardRadius: Int = 18       // 4/18/28
    @Published var blurStrength: Int = 1      // 0=无, 1=轻, 2=强
    @Published var bedtimeReminderEnabled: Bool = true
    @Published var backgroundRunning: Bool = true
    @Published var controlCodeEnabled: Bool = true

    // MARK: - 控制码 & 账户
    @Published var controlCode: String = ""
    @Published var nickname: String = "未命名"
    @Published var agreed: Bool = false

    // MARK: - 运行状态
    @Published var isSleeping: Bool = false
    @Published var sleepStartMillis: Double = 0
    @Published var lastNagMillis: Double = 0

    // MARK: - 屏蔽应用包名（iOS 不支持实际屏蔽，仅记录）
    @Published var blockedPackages: Set<String> = []

    // MARK: - 睡眠记录
    @Published var recordLines: Set<String> = []

    private let defaults = UserDefaults.standard

    private init() { load() }

    func load() {
        let d = defaults
        bedtimeMinutes = d.integer(forKey: "bed")
        if bedtimeMinutes == 0 { bedtimeMinutes = 23 * 60 }
        waketimeMinutes = d.integer(forKey: "wake")
        if waketimeMinutes == 0 { waketimeMinutes = 7 * 60 }
        supervisionEnabled = d.object(forKey: "sup") as? Bool ?? true
        darkMode = d.bool(forKey: "dark")
        leadMinutes = d.integer(forKey: "lead"); if leadMinutes == 0 { leadMinutes = 30 }
        nagMinutes = d.integer(forKey: "nag"); if nagMinutes == 0 { nagMinutes = 10 }
        navStyle = d.integer(forKey: "nav_style")
        fontScale = d.double(forKey: "font_scale"); if fontScale == 0 { fontScale = 1.0 }
        fontStyle = d.integer(forKey: "font_style")
        cardRadius = d.integer(forKey: "card_radius"); if cardRadius == 0 { cardRadius = 18 }
        blurStrength = d.integer(forKey: "blur_strength"); if blurStrength == 0 { blurStrength = 1 }
        bedtimeReminderEnabled = d.object(forKey: "bed_reminder") as? Bool ?? true
        backgroundRunning = d.object(forKey: "bg_run") as? Bool ?? true
        controlCodeEnabled = d.object(forKey: "control_code_enabled") as? Bool ?? true
        controlCode = d.string(forKey: "control_code") ?? ""
        nickname = d.string(forKey: "nickname") ?? "未命名"
        agreed = d.bool(forKey: "agreed")
        isSleeping = d.bool(forKey: "sleeping")
        sleepStartMillis = d.double(forKey: "start")
        lastNagMillis = d.double(forKey: "lastNag")
        blockedPackages = Set(d.stringArray(forKey: "blocked") ?? [])
        recordLines = Set(d.stringArray(forKey: "records") ?? [])
    }

    func save() {
        let d = defaults
        d.set(bedtimeMinutes, forKey: "bed")
        d.set(waketimeMinutes, forKey: "wake")
        d.set(supervisionEnabled, forKey: "sup")
        d.set(darkMode, forKey: "dark")
        d.set(leadMinutes, forKey: "lead")
        d.set(nagMinutes, forKey: "nag")
        d.set(navStyle, forKey: "nav_style")
        d.set(fontScale, forKey: "font_scale")
        d.set(fontStyle, forKey: "font_style")
        d.set(cardRadius, forKey: "card_radius")
        d.set(blurStrength, forKey: "blur_strength")
        d.set(bedtimeReminderEnabled, forKey: "bed_reminder")
        d.set(backgroundRunning, forKey: "bg_run")
        d.set(controlCodeEnabled, forKey: "control_code_enabled")
        d.set(controlCode, forKey: "control_code")
        d.set(nickname, forKey: "nickname")
        d.set(agreed, forKey: "agreed")
        d.set(isSleeping, forKey: "sleeping")
        d.set(sleepStartMillis, forKey: "start")
        d.set(lastNagMillis, forKey: "lastNag")
        d.set(Array(blockedPackages), forKey: "blocked")
        d.set(Array(recordLines), forKey: "records")
    }

    // MARK: - 控制码生成
    private static let codeChars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    func ensureControlCode() {
        guard controlCode.isEmpty else { return }
        let raw = (0..<10).map { _ in
            String(Store.codeChars[Int.random(in: 0..<Store.codeChars.count)])
        }.joined()
        controlCode = raw.prefix(4) + "-" + raw.dropFirst(4).prefix(4) + "-" + raw.dropFirst(8)
        save()
    }

    // MARK: - 睡眠状态
    func startSleep() {
        isSleeping = true
        sleepStartMillis = Date().timeIntervalSince1970 * 1000
        save()
    }

    func endSleep() {
        guard isSleeping, sleepStartMillis > 0 else { return }
        let endMs = Date().timeIntervalSince1970 * 1000
        let hours = max(0, (endMs - sleepStartMillis) / 3_600_000)
        let bedMin = TimeUtil.minuteOfDay(Date(timeIntervalSince1970: sleepStartMillis / 1000))
        let wakeMin = TimeUtil.minuteOfDay(Date(timeIntervalSince1970: endMs / 1000))
        let offset = bedMin < waketimeMinutes ? -1 : 0
        let night = TimeUtil.dateStr(Date(timeIntervalSince1970: sleepStartMillis / 1000), offsetDays: offset)
        let rec = SleepRecord(nightDate: night, bedMinutes: bedMin, wakeMinutes: wakeMin, sleepHours: hours)
        recordLines = recordLines.filter { !$0.hasPrefix(night + "|") }
        recordLines.insert(rec.serialize())
        isSleeping = false
        sleepStartMillis = 0
        save()
    }

    func recentRecords(_ n: Int) -> [SleepRecord] {
        recordLines
            .compactMap(SleepRecord.parse)
            .sorted { $0.nightDate > $1.nightDate }
            .prefix(n)
            .map { $0 }
    }
}
