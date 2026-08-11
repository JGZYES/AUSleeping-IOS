import Foundation

/// HTTP 客户端：与 api.ausleep.parlz.com 通信
enum ApiClient {
    private static let base = "http://api.ausleep.parlz.com"
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d
    }()

    struct ApiResult: Codable {
        let ok: Bool
        let error: String?
    }

    /// 注册控制码
    static func bind(code: String, nickname: String) async -> ApiResult {
        post("/register.php", body: ["code": code, "nickname": nickname])
    }

    /// 同步状态 + 拉取指令
    static func sync(code: String, body: [String: Any]) async -> ApiResult {
        var b = body; b["code"] = code
        return post("/sync.php", body: b)
    }

    /// 查询朋友信息
    static func friendInfo(code: String) async -> [String: Any]? {
        do {
            let res = try await postDict("/friend_info.php", body: ["friend_code": code])
            return res
        } catch { return nil }
    }

    /// 朋友设置就寝时间
    static func friendSetBedtime(friendCode: String, bedtime: Int, waketime: Int) async -> ApiResult {
        post("/friend_set_bedtime.php", body: ["friend_code": friendCode, "bedtime": bedtime, "waketime": waketime])
    }

    /// 朋友触发指令 (sleep/wake/message)
    static func friendTrigger(friendCode: String, action: String, message: String = "") async -> ApiResult {
        post("/friend_trigger.php", body: ["friend_code": friendCode, "action": action, "message": message])
    }

    /// 检查更新
    static func checkUpdate(versionCode: Int) async -> [String: Any]? {
        do {
            return try await postDict("/check_update.php", body: ["version_code": versionCode])
        } catch { return nil }
    }

    // MARK: - 底层 HTTP

    private static func post(_ path: String, body: [String: Any]) -> ApiResult {
        do {
            let data = try postData(path, body: body)
            return try decoder.decode(ApiResult.self, from: data)
        } catch {
            return ApiResult(ok: false, error: error.localizedDescription)
        }
    }

    private static func postDict(_ path: String, body: [String: Any]) async throws -> [String: Any] {
        let data = try await postDataAsync(path, body: body)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return json
    }

    private static func postData(_ path: String, body: [String: Any]) throws -> Data {
        var semaphoreResult: Result<Data, Error> = .failure(URLError(.unknown))
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do { semaphoreResult = .success(try await postDataAsync(path, body: body)) }
            catch { semaphoreResult = .failure(error) }
            semaphore.signal()
        }
        semaphore.wait()
        return try semaphoreResult.get()
    }

    private static func postDataAsync(_ path: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return data
    }
}
