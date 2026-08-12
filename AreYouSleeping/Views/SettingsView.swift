import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var showAgreement = false
    @State private var showStyleSettings = false
    @State private var showTimePicker = false
    @State private var isBedPicker = false
    @State private var pickerDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 控制码
                Section {
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
                            }
                        }
                    }
                    Toggle("启用控制码功能", isOn: $store.controlCodeEnabled)
                        .onChange(of: store.controlCodeEnabled) { _ in store.save() }
                } header: { Text("控制码") }

                // MARK: - 作息
                Section {
                    HStack {
                        Text("目标就寝时间")
                        Spacer()
                        Text(TimeUtil.fmt(store.bedtimeMinutes)).foregroundColor(.blue)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showTimePickerSheet(isBed: true) }

                    HStack {
                        Text("目标起床时间")
                        Spacer()
                        Text(TimeUtil.fmt(store.waketimeMinutes)).foregroundColor(.blue)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { showTimePickerSheet(isBed: false) }
                } header: { Text("作息") }

                // MARK: - 提醒
                Section {
                    Toggle("睡前 30 分钟提醒", isOn: $store.bedtimeReminderEnabled)
                        .onChange(of: store.bedtimeReminderEnabled) { _ in
                            store.save()
                            BedtimeReminder.schedule(store: store)
                        }
                } header: { Text("提醒") } footer: {
                    Text("睡觉时间前发送通知提醒你准备休息")
                }

                // MARK: - 监督
                Section {
                    Toggle("监督模式", isOn: $store.supervisionEnabled)
                        .onChange(of: store.supervisionEnabled) { _ in store.save() }
                } header: { Text("监督") } footer: {
                    Text("就寝时段提醒你放下手机")
                }

                // MARK: - 后台运行
                Section {
                    Toggle("允许后台运行", isOn: $store.backgroundRunning)
                        .onChange(of: store.backgroundRunning) { _ in store.save() }
                } header: { Text("后台运行") } footer: {
                    Text("关闭后应用切到后台将停止服务")
                }

                // MARK: - 样式
                Section {
                    NavigationLink {
                        StyleSettingsView()
                    } label: {
                        Text("样式")
                    }
                } header: { Text("外观") }

                // MARK: - 朋友
                Section {
                    NavigationLink("控制朋友") {
                        FriendControlView()
                    }
                } header: { Text("朋友") }

                // MARK: - 其他
                Section {
                    Button("用户协议与隐私说明") { showAgreement = true }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showAgreement) {
                AgreementView()
            }
            .sheet(isPresented: $showTimePicker) {
                timePickerSheet
                    .presentationDetents([.height(300)])
            }
        }
    }

    // MARK: - 时间选择器（纯 SwiftUI）
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
                .datePickerStyle(.wheel)
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
}
