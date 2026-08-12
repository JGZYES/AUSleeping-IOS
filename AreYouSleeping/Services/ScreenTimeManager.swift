import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import SwiftUI

/// 屏幕时间管理器 — 授权、应用选择、定时屏蔽
@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var isAuthorized = false
    @Published var selection = FamilyActivitySelection()
    @Published var blockedAppCount = 0

    private let center = DeviceActivityCenter()
    private let shieldStore = ManagedSettingsStore()
    private let sharedDefaults = UserDefaults(suiteName: "group.com.areyousleeping")!

    private init() {
        refreshAuth()
        loadSelection()
    }

    // MARK: - 授权

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            print("ScreenTime auth failed: \(error)")
            isAuthorized = false
        }
    }

    func refreshAuth() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - 选择屏蔽应用

    func saveSelection(_ sel: FamilyActivitySelection) {
        selection = sel
        blockedAppCount = sel.applicationTokens.count + sel.categoryTokens.count

        // 持久化到 App Group，供 Extension 读取
        let dict: [String: Any] = ["appCount": blockedAppCount]
        sharedDefaults.set(dict, forKey: "shield_info")

        // 直接写入 ManagedSettings（即使 App 被杀也生效）
        shieldStore.shield.applications = sel.applicationTokens.isEmpty ? nil : sel.applicationTokens
        shieldStore.shield.applicationCategories = sel.categoryTokens.isEmpty
            ? nil
            : .specific(sel.categoryTokens)

        // 根据当前作息调度 DeviceActivity
        let store = Store.shared
        scheduleMonitoring(bedMin: store.bedtimeMinutes, wakeMin: store.waketimeMinutes)
    }

    private func loadSelection() {
        blockedAppCount = sharedDefaults.integer(forKey: "shield_count")
    }

    // MARK: - DeviceActivity 调度

    func scheduleMonitoring(bedMin: Int, wakeMin: Int) {
        center.stopAllMonitoring()
        guard blockedAppCount > 0 else { return }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: bedMin / 60, minute: bedMin % 60),
            intervalEnd:   DateComponents(hour: wakeMin / 60, minute: wakeMin % 60),
            repeats: true
        )
        do {
            try center.startMonitoring(.sleep, during: schedule)
        } catch {
            print("DeviceActivity start fail: \(error)")
        }
    }

    func stopMonitoring() {
        center.stopAllMonitoring()
    }

    // MARK: - 手动开关屏蔽

    func applyShieldNow() {
        shieldStore.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        shieldStore.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
    }

    func removeShieldNow() {
        shieldStore.shield.applications = nil
        shieldStore.shield.applicationCategories = nil
    }
}

extension DeviceActivityName {
    static let sleep = Self("com.areyousleeping.sleep")
}
