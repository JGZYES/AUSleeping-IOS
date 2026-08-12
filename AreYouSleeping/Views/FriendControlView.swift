import SwiftUI

struct FriendControlView: View {
    @EnvironmentObject var store: Store
    @State private var friendCode = ""
    @State private var friendInfo: String?
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 查询卡片
                VStack(spacing: 12) {
                    HStack {
                        TextField("输入朋友的控制码", text: $friendCode)
                            .disableAutocorrection(true)
                            .textCase(.uppercase)
                        Button("查询") { lookupFriend() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(friendCode.isEmpty || isLoading)
                    }

                    if isLoading {
                        ProgressView()
                    }

                    if let info = friendInfo {
                        Text(info)
                            .font(.headline)
                            .foregroundColor(.green)
                    }

                    if let error = errorMsg {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .glassCard()

                // 远程控制卡片
                if friendInfo != nil {
                    VStack(spacing: 8) {
                        Button {
                            sendCommand("sleep")
                        } label: {
                            Label("提醒入睡", systemImage: "moon.zzz.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.indigo)

                        Button {
                            sendCommand("wake")
                        } label: {
                            Label("提醒起床", systemImage: "sunrise.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("控制朋友").font(.headline)
            }
        }
    }

    private func lookupFriend() {
        isLoading = true
        errorMsg = nil
        friendInfo = nil
        Task {
            let info = await ApiClient.friendInfo(code: friendCode)
            await MainActor.run {
                isLoading = false
                if let nick = info?["nickname"] as? String {
                    friendInfo = "昵称：\(nick)"
                } else if let ok = info?["ok"] as? Bool, !ok {
                    errorMsg = (info?["error"] as? String) ?? "找不到该控制码"
                } else {
                    friendInfo = "已连接（昵称未知）"
                }
            }
        }
    }

    private func sendCommand(_ cmd: String) {
        Task {
            let result = await ApiClient.friendTrigger(friendCode: friendCode, action: cmd)
            await MainActor.run {
                if !result.ok {
                    errorMsg = "指令失败：\(result.error ?? "未知错误")"
                }
            }
        }
    }
}
