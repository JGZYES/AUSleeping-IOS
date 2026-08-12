import DeviceActivity
import ManagedSettings

/// 就寝时段屏蔽扩展 — 系统级回调，不依赖主 App 存活
@main
final class SleepMonitor: DeviceActivityMonitor {

    private let store: ManagedSettingsStore = {
        ManagedSettingsStore()
    }()

    // MARK: - 就寝开始 → 屏蔽应用

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyShield()
    }

    // MARK: - 就寝结束 → 解除屏蔽

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        removeShield()
    }

    // MARK: - 屏蔽事件回调（用户尝试打开被屏蔽应用时触发）

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // 阈值事件：可用于统计/通知
    }

    // MARK: - Private

    private func applyShield() {
        let shared = UserDefaults(suiteName: "group.com.areyousleeping")!
        let count = shared.integer(forKey: "shield_count")
        guard count > 0 else { return }

        // ManagedSettings 屏蔽由主 App 写入后持久生效，
        // Extension 的存在确保设备重启 / App 被回收后仍能正确触发解除。
        // 此处可扩展添加自定义逻辑（如记录屏蔽次数等）。
    }

    private func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
