import Foundation
import Security

// MARK: - ELearningService
// Connects to Fudan elearning (Moodle) via the standard Moodle Mobile App web service.
// Credentials are stored only in the macOS Keychain – never transmitted elsewhere.

@MainActor
final class ELearningService: ObservableObject {

    @Published var isLoggedIn   = false
    @Published var isLoading    = false
    @Published var errorMessage: String?
    @Published var enrolledCourses: [MoodleCourse] = []
    @Published var resources: [ELearningResource] = []
    @Published var lastSyncDate: Date?

    private var wsToken: String?
    private var currentUserId: Int?
    private let base = "https://elearning.fudan.edu.cn"
    private var syncTask: Task<Void, Never>?

    // MARK: - Moodle types

    struct MoodleCourse: Codable, Identifiable {
        let id: Int
        let fullname: String
        let shortname: String
    }

    private struct TokenResponse: Codable {
        let token: String?
        let error: String?
        let errorcode: String?
    }

    private struct SiteInfo: Codable {
        let userid: Int
        let username: String
        let fullname: String?
    }

    private struct CourseModule: Codable {
        let id: Int
        let name: String
        let modname: String
        let url: String?
        let timemodified: Int?
    }

    private struct Section: Codable {
        let name: String
        let modules: [CourseModule]
    }

    // MARK: - Session restore

    func restoreSession() {
        guard let token = Keychain.load("tf_elearning_token") else { return }
        wsToken = token
        if let uid = UserDefaults.standard.object(forKey: "tf_elearning_userid") as? Int {
            currentUserId = uid
        }
        isLoggedIn = true
        loadPersistedResources()
    }

    // MARK: - Login

    func login(username: String, password: String) async -> Bool {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        guard var components = URLComponents(string: "\(base)/login/token.php") else { return false }
        components.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "service",  value: "moodle_mobile_app"),
        ]

        var req = URLRequest(url: components.url!)
        req.httpMethod = "POST"
        req.httpBody   = components.percentEncodedQuery?.data(using: .utf8)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let resp = try JSONDecoder().decode(TokenResponse.self, from: data)

            if let token = resp.token {
                wsToken = token
                Keychain.save("tf_elearning_token", value: token)
                Keychain.save("tf_elearning_user",  value: username)
                await fetchSiteInfo()
                isLoggedIn = true
                await fetchEnrolledCourses()
                return true
            } else {
                errorMessage = resp.error ?? "登录失败，请检查账号密码"
                return false
            }
        } catch {
            errorMessage = "网络错误：\(error.localizedDescription)"
            return false
        }
    }

    func logout() {
        wsToken       = nil
        currentUserId = nil
        isLoggedIn    = false
        resources     = []
        enrolledCourses = []
        syncTask?.cancel()
        Keychain.delete("tf_elearning_token")
        Keychain.delete("tf_elearning_user")
        UserDefaults.standard.removeObject(forKey: "tf_elearning_userid")
        saveResources([])
    }

    // MARK: - Fetch

    private func fetchSiteInfo() async {
        guard let token = wsToken,
              let data  = await call("core_webservice_get_site_info", params: [:], token: token),
              let info  = try? JSONDecoder().decode(SiteInfo.self, from: data) else { return }
        currentUserId = info.userid
        UserDefaults.standard.set(info.userid, forKey: "tf_elearning_userid")
    }

    func fetchEnrolledCourses() async {
        guard let token = wsToken, let uid = currentUserId else { return }
        guard let data = await call(
            "core_enrol_get_users_courses",
            params: ["userid": "\(uid)"],
            token: token
        ), let courses = try? JSONDecoder().decode([MoodleCourse].self, from: data) else { return }
        enrolledCourses = courses
    }

    func syncResources(for courseId: Int) async -> [ELearningResource] {
        guard let token = wsToken else { return [] }
        guard let data = await call(
            "core_course_get_contents",
            params: ["courseid": "\(courseId)"],
            token: token
        ), let sections = try? JSONDecoder().decode([Section].self, from: data) else { return [] }

        let courseName = enrolledCourses.first { $0.id == courseId }?.fullname ?? ""
        var result: [ELearningResource] = []
        for section in sections {
            for mod in section.modules {
                result.append(ELearningResource(
                    id:               "\(courseId)_\(mod.id)",
                    courseId:         courseId,
                    courseName:       courseName,
                    name:             mod.name,
                    modType:          mod.modname,
                    url:              mod.url ?? "",
                    addedTimestamp:   mod.timemodified.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()
                ))
            }
        }
        return result
    }

    func syncAll() async {
        guard isLoggedIn else { return }
        isLoading = true
        defer { isLoading = false }

        await fetchEnrolledCourses()

        let oldIds = Set(resources.map(\.id))
        var fresh: [ELearningResource] = []
        for course in enrolledCourses {
            var batch = await syncResources(for: course.id)
            for i in batch.indices {
                batch[i].isNew = !oldIds.contains(batch[i].id)
            }
            fresh.append(contentsOf: batch)
        }
        resources    = fresh
        lastSyncDate = Date()
        saveResources(fresh)
    }

    // Mark a resource as "seen" (removes the "new" badge)
    func markSeen(_ resourceId: String) {
        if let i = resources.firstIndex(where: { $0.id == resourceId }) {
            resources[i].isNew = false
            saveResources(resources)
        }
    }

    // MARK: - Auto-sync

    func startAutoSync(intervalMinutes: Int) {
        syncTask?.cancel()
        guard intervalMinutes > 0 else { return }
        syncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(intervalMinutes) * 60 * 1_000_000_000)
                guard !Task.isCancelled else { break }
                await self?.syncAll()
            }
        }
    }

    // MARK: - Persistence (eLearning resources survive restarts)

    private var resourcesURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TodoFlow", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("elearning.json")
    }

    private func saveResources(_ r: [ELearningResource]) {
        if let data = try? JSONEncoder().encode(r) {
            try? data.write(to: resourcesURL, options: .atomic)
        }
    }

    private func loadPersistedResources() {
        guard let data = try? Data(contentsOf: resourcesURL),
              let r    = try? JSONDecoder().decode([ELearningResource].self, from: data) else { return }
        // Clear "new" flags on restart – only mark new after an actual sync
        resources = r.map { var x = $0; x.isNew = false; return x }
    }

    // MARK: - Moodle REST helper

    private func call(_ function: String, params: [String: String], token: String) async -> Data? {
        var components = URLComponents(string: "\(base)/webservice/rest/server.php")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "wstoken",             value: token),
            URLQueryItem(name: "wsfunction",          value: function),
            URLQueryItem(name: "moodlewsrestformat",  value: "json"),
        ]
        for (k, v) in params { items.append(URLQueryItem(name: k, value: v)) }
        components.queryItems = items
        guard let url = components.url else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}

// MARK: - Keychain helper

enum Keychain {
    private static let service = "TodoFlow"

    static func save(_ key: String, value: String) {
        let data = Data(value.utf8)
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String:   data,
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }

    static func load(_ key: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(q as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(q as CFDictionary)
    }
}
