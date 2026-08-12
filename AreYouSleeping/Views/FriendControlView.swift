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
            let result = await ApiClient.query(code: friendCode)
            isLoading = false
            switch result {
            case .success(let info):
                friendInfo = info
            case .failure(let e):
                errorMsg = "查询失败：\(e.localizedDescription)"
            }
        }
    }

    private func sendCommand(_ cmd: String) {
        Task {
            let result = await ApiClient.command(code: friendCode, cmd: cmd)
            await MainActor.run {
                if case .failure(let e) = result {
                    errorMsg = "指令失败：\(e.localizedDescription)"
                }
            }
        }
    }
}
