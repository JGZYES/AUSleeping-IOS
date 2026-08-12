import SwiftUI

struct StyleSettingsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 暗色模式
                styleCard {
                    Toggle("暗色模式", isOn: $store.darkMode)
                        .onChange(of: store.darkMode) { _ in store.save() }
                } header: { Text("主题") }

                // 导航栏
                styleCard {
                    VStack(spacing: 8) {
                        Picker("导航栏样式", selection: $store.navStyle) {
                            Text("默认").tag(0)
                            Text("无边框").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: store.navStyle) { _ in store.save() }
                    }
                } header: { Text("导航栏") }

                // 字体
                styleCard {
                    VStack(spacing: 12) {
                        Picker("字体风格", selection: $store.fontStyle) {
                            Text("默认").tag(0)
                            Text("圆体").tag(1)
                            Text("等宽").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: store.fontStyle) { _ in store.save() }

                        VStack(spacing: 4) {
                            HStack {
                                Text("字体大小: \(String(format: "%.0f%%", store.fontScale * 100))")
                                    .font(.subheadline)
                                Spacer()
                                Button("重置") { store.fontScale = 1.0; store.save() }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                            }
                            Slider(value: $store.fontScale, in: 0.85...1.30, step: 0.05)
                                .onChange(of: store.fontScale) { _ in store.save() }
                        }
                    }
                } header: { Text("字体") }

                // 卡片
                styleCard {
                    Picker("卡片圆角", selection: $store.cardRadius) {
                        Text("小 (4)").tag(4)
                        Text("中 (18)").tag(18)
                        Text("大 (28)").tag(28)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: store.cardRadius) { _ in store.save() }
                } header: { Text("卡片") }

                // 模糊
                styleCard {
                    Picker("模糊强度", selection: $store.blurStrength) {
                        Text("无").tag(0)
                        Text("轻微").tag(1)
                        Text("强烈").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: store.blurStrength) { _ in store.save() }
                } header: { Text("模糊") }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("样式设置").font(.headline)
            }
        }
    }

    @ViewBuilder
    private func styleCard<Content: View, Header: View>(
        @ViewBuilder content: () -> Content,
        header: () -> Header
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            header()
                .font(.caption)
                .foregroundColor(.secondary)
            content()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassCard(radius: 14)
        }
    }
}
