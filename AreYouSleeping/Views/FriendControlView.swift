import SwiftUI

struct FriendControlView: View {
    @EnvironmentObject var store: Store
    @State private var friendCode = ""
    @State private var friendInfo: String?
    @State private var isLoading = false
    @State private var errorMsg: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("输入朋友的控制码", text: $friendCode)
                        .disableAutocorrection(true)
                        .textCase(.uppercase)
                    Button("查询") { lookupFriend() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(friendCode.isEmpty || isLoading)
                }
            }

            if let info = friendInfo {
                Section("朋友信息") {
                    Text(info).font(.headline)
                }
            }

            if let error = errorMsg {
                Section { Text(error).foregroundColor(.red) }
            }

            if friendInfo != nil {
                Section("操作") {
                    Button { triggerFriend("sleep") } label: {
                        Label("催朋友睡觉", systemImage: "moon.zzz.fill")
                    }
                    Button { triggerFriend("wake") } label: {
                        Label("叫朋友起床", systemImage: "sunrise.fill")
                    }
                }
            }
        }
        .navigationTitle("控制朋友")
        .overlay { if isLoading { ProgressView() } }
    }

    private func lookupFriend() {
        isLoading = true; errorMsg = nil; friendInfo = nil
        Task {
            if let res = await ApiClient.friendInfo(code: friendCode) {
                friendInfo = (res["nickname"] as? String) ?? friendCode
            } else {
                errorMsg = "未找到该用户"
            }
            isLoading = false
        }
    }

    private func triggerFriend(_ action: String) {
        Task {
            let res = await ApiClient.friendTrigger(friendCode: friendCode, action: action)
            if !res.ok { errorMsg = res.error ?? "操作失败" }
        }
    }
}
