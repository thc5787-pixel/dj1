import Foundation
import Observation

enum VoHiveAuthState: Equatable {
    case unconfigured
    case signedOut
    case signingIn
    case signedIn
    case failed(String)

    var title: String {
        switch self {
        case .unconfigured: "未配置服务器"
        case .signedOut: "未登录"
        case .signingIn: "登录中"
        case .signedIn: "已登录"
        case .failed: "登录失败"
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
}

@MainActor
@Observable
final class VoHiveAuthStore {
    private let client: VoHiveClient
    private let serverSettings: ServerSettingsStore
    private let secureStore: any SecureValueStoring
    private let defaults: UserDefaults
    private let tokenKey = "vohive.accessToken"
    private let usernameKey = "vohive.username"

    private(set) var state: VoHiveAuthState = .unconfigured
    private(set) var authenticatedServerURL: String?
    var username: String
    var password = ""

    init(
        client: VoHiveClient,
        serverSettings: ServerSettingsStore,
        secureStore: any SecureValueStoring = KeychainStore(),
        defaults: UserDefaults = .standard
    ) {
        self.client = client
        self.serverSettings = serverSettings
        self.secureStore = secureStore
        self.defaults = defaults
        self.username = defaults.string(forKey: usernameKey) ?? ""
    }

    var isSignedIn: Bool { state.isSignedIn }

    func restore() async {
        guard let configuration = serverSettings.configuration else {
            state = .unconfigured
            return
        }
        let storedToken = try? secureStore.readString(for: tokenKey)
        await client.configure(baseURL: configuration.baseURL, token: storedToken)
        if let storedToken, !storedToken.isEmpty {
            authenticatedServerURL = configuration.displayValue
            state = .signedIn
        } else {
            state = .signedOut
        }
    }

    func login() async {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            state = .failed("请输入用户名和密码。")
            return
        }
        guard let configuration = serverSettings.configuration else {
            state = .unconfigured
            return
        }
        state = .signingIn
        do {
            await client.configure(baseURL: configuration.baseURL, token: nil)
            let response = try await client.login(username: trimmedUsername, password: password)
            try secureStore.write(response.token, for: tokenKey)
            defaults.set(trimmedUsername, forKey: usernameKey)
            authenticatedServerURL = configuration.displayValue
            password = ""
            state = .signedIn
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func logout() {
        try? secureStore.deleteValue(for: tokenKey)
        Task { await client.setToken(nil) }
        password = ""
        authenticatedServerURL = nil
        state = serverSettings.isConfigured ? .signedOut : .unconfigured
    }

    func handleUnauthorized() {
        try? secureStore.deleteValue(for: tokenKey)
        Task { await client.setToken(nil) }
        password = ""
        authenticatedServerURL = nil
        state = .failed("登录已失效，请重新登录。")
    }

    func serverConfigurationChanged() {
        guard let configuration = serverSettings.configuration else {
            logout()
            return
        }
        if let authenticatedServerURL,
           authenticatedServerURL != configuration.displayValue {
            logout()
        } else if state == .unconfigured {
            state = .signedOut
        }
    }
}
