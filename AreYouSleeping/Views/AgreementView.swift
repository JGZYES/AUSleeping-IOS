import SwiftUI

struct AgreementView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(red: 0.84, green: 0.84, blue: 0.87)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("用户协议与隐私说明")
                            .font(.title).bold()

                        Text("欢迎使用「睡了吗」。\n\n本协议说明应用功能与数据使用方式，请仔细阅读。")
                            .font(.body).foregroundColor(.secondary)

                        agreementSection("一、应用功能") {
                            Text("1. 睡眠监督：在您设定的就寝时段，提醒您按时入睡。\n（注：iOS 系统限制，本应用无法直接屏蔽其他应用，仅提供通知提醒。）\n2. 作息记录：记录您的入睡与起床时间，生成睡眠统计。\n3. 控制码功能（见第二条）。")
                        }

                        agreementSection("二、控制码功能") {
                            Text("本应用会为您的手机生成一个独一无二的控制码。\n\n• 控制码绑定本机，卸载重装后才会变更。\n• 您可以将控制码分享给朋友。朋友输入您的控制码后可以远程设置您的就寝/起床时间、提醒您入睡/起床。\n• 您可以随时在设置中停止分享。\n• 请仅将控制码分享给您信任的人。")
                        }

                        agreementSection("三、数据与隐私") {
                            Text("• 您的作息设置、睡眠记录会同步到服务器，以便朋友通过控制码查看和远程操作。\n• 服务器仅存储与功能相关的必要数据，不会出售或分享给第三方。\n• 您可以在应用设置中随时停止监督服务，断开与服务器同步。")
                        }

                        agreementSection("四、所需权限") {
                            Text("• 通知：发送就寝提醒与朋友远程消息\n• 网络访问：与服务器同步作息数据、接收朋友远程指令")
                        }

                        Spacer().frame(height: 16)

                        VStack(spacing: 4) {
                            Text("解释权归 JGZ_YES 所有")
                                .font(.footnote).foregroundColor(.secondary)
                            Text("(c) 2026 JGZ_YES")
                                .font(.footnote).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                }

                // 底部按钮
                HStack(spacing: 12) {
                    Button("不同意") {
                        exit(0)
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    .controlSize(.large)

                    Button("同意并继续") {
                        store.agreed = true
                        store.ensureControlCode()
                        store.save()
                        Task {
                            _ = await ApiClient.bind(code: store.controlCode, nickname: store.nickname)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
    }

    @ViewBuilder
    private func agreementSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content().font(.subheadline).foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}
