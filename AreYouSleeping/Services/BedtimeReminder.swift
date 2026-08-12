import UserNotifications

/// 睡前 30 分钟提醒调度器（iOS 使用 UNUserNotificationCenter）
enum BedtimeReminder {

    @MainActor
    static func schedule(store: Store) {
        guard store.agreed, store.bedtimeReminderEnabled else {
            cancel()
            return
        }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let triggerDate = calcNextTrigger(bedtimeMinutes: store.bedtimeMinutes)
            let content = UNMutableNotificationContent()
            content.title = "睡了吗 · 就寝提醒"
            content.body = "还有 30 分钟到您的睡觉时间 \(TimeUtil.fmt(store.bedtimeMinutes))，准备休息啦~"
            content.sound = .default
            content.categoryIdentifier = "BEDTIME_REMINDER"

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: "bedtime_reminder",
                                                content: content,
                                                trigger: trigger)
            center.add(request) { error in
                if let e = error { print("BedtimeReminder schedule error: \(e)") }
            }
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["bedtime_reminder"])
    }

    /// 计算下一次提醒时间（bedtime 前 30 分钟）
    private static func calcNextTrigger(bedtimeMinutes: Int) -> Date {
        let minutesBefore = 30
        var reminderMin = bedtimeMinutes - minutesBefore
        if reminderMin < 0 { reminderMin += 24 * 60 }

        var cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = reminderMin / 60
        comps.minute = reminderMin % 60
        comps.second = 0

        var candidate = cal.date(from: comps) ?? Date()
        if candidate <= Date() {
            candidate = cal.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }

    /// 请求通知权限
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
