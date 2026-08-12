import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var showAgreement = false
    @State private var showTimePicker = false
    @State private var isBedPicker = false
    @State private var pickerDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 控制码卡片
                    cardSection(header: "控制码") {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("我的控制码").font(.caption).foregroundColor(.secondary)
                                    Text(store.controlCode.isEmpty ? "----" : store.controlCode)
                                        .font(.title3).bold().foregroundColor(.blue)
                                }
                                Spacer()
                                if !store.controlCode.isEmpty {
                                    ShareLink(item: shareText) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title3)
                                    }
                                }
                            }
                            Divider()
                            Toggle("启用控制码功能", isOn: $store.controlCodeEnabled)
                                .onChange(of: store.controlCodeEnabled) { _ in store.save() }
                        }
                    }

                    // 作息卡片
                    cardSection(header: "作息") {
                        VStack(spacing: 0) {
                            timeRow(title: "目标就寝时间", minutes: store.bedtimeMinutes) {
                                showTimePickerSheet(isBed: true)
                            }
                            Divider().padding(.leading, 16)
                            timeRow(title: "目标起床时间", minutes: store.waketimeMinutes) {
                                showTimePickerSheet(isBed: false)
                            }
                        }
                    }

                    // 提醒卡片
                    cardSection(header: "提醒", footer: "睡觉时间前发送通知提醒你准备休息") {
                        Toggle("睡前 30 分钟提醒", isOn: $store.bedtimeReminderEnabled)
                            .onChange(of: store.bedtimeReminderEnabled) { _ in
                                store.save()
                                BedtimeReminder.schedule(store: store)
                            }
                    }

                    // 监督卡片
                    cardSection(header: "监督", footer: "就寝时段提醒你放下手机") {
                        Toggle("监督模式", isOn: $store.supervisionEnabled)
                            .onChange(of: store.supervisionEnabled) { _ in store.save() }
                    }

                    // 后台运行卡片
                    cardSection(header: "后台运行", footer: "关闭后应用切到后台将停止服务") {
                        Toggle("允许后台运行", isOn: $store.backgroundRunning)
                            .onChange(of: store.backgroundRunning) { _ in store.save() }
                    }

                    // 外观
                    cardSection(header: "外观") {
                        NavigationLink {
                            StyleSettingsView()
                        } label: {
                            HStack {
                                Text("样式")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }

                    // 朋友
                    cardSection(header: "朋友") {
                        NavigationLink("控制朋友") {
                            FriendControlView()
                        }
                        .foregroundColor(.primary)
                    }

                    // 其他
                    cardSection {
                        Button("用户协议与隐私说明") { showAgreement = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("设置").font(.headline)
                }
            }
            .sheet(isPresented: $showAgreement) {
                AgreementView()
            }
            .sheet(isPresented: $showTimePicker) {
                timePickerSheet
                    .presentationDetents([.height(300)])
            }
        }
    }

    // MARK: - 时间选择器
    private var timePickerSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Button("取消") { showTimePicker = false }
                Spacer()
                Text(isBedPicker ? "就寝时间" : "起床时间").font(.headline)
                Spacer()
                Button("确定") {
                    let cal = Calendar.current
                    let h = cal.component(.hour, from: pickerDate)
                    let m = cal.component(.minute, from: pickerDate)
                    let v = h * 60 + m
                    if isBedPicker {
                        store.bedtimeMinutes = v
                        BedtimeReminder.schedule(store: store)
                    } else {
                        store.waketimeMinutes = v
                    }
                    store.save()
                    showTimePicker = false
                }
                .bold()
            }
            .padding(.horizontal)

            DatePicker("", selection: $pickerDate, displayedComponents: .hourAndMinute)
                .labelsHidden()
        }
        .padding(.top, 12)
    }

    private func showTimePickerSheet(isBed: Bool) {
        isBedPicker = isBed
        let curMin = isBed ? store.bedtimeMinutes : store.waketimeMinutes
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = curMin / 60
        comps.minute = curMin % 60
        pickerDate = cal.date(from: comps) ?? Date()
        showTimePicker = true
    }

    private var shareText: String {
        let code = store.controlCode
        let webLink = "http://api.ausleep.parlz.com/control?code=\(code)"
        return """
              我在用「睡了吗」监督睡眠，这是我的控制码：\(code)
              点击链接直接连接（需安装「睡了吗」）：
              \(webLink)
              """
    }

    // MARK: - 组件

    @ViewBuilder
    private func timeRow(title: String, minutes: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(TimeUtil.fmt(minutes))
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private func cardSection(header: String? = nil, footer: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let h = header {
                Text(h)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassCard(radius: 14)
            if let f = footer {
                Text(f)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}
