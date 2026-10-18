import Foundation
import Observation

enum ServerConfigurationError: LocalizedError, Equatable {
    case empty
    case invalidURL
    case insecureScheme

    var errorDescription: String? {
        switch self {
        case .empty: "请输入服务器地址。"
        case .invalidURL: "请输入有效的服务器地址。"
        case .insecureScheme: "服务器必须使用 HTTPS（本地调试地址除外）。"
        }
    }
}

struct ServerConfiguration: Equatable, Sendable {
    let baseURL: URL

    init(rawValue: String) throws {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ServerConfigurationError.empty }
        guard let url = URL(string: trimmed), let host = url.host, !host.isEmpty else { throw ServerConfigurationError.invalidURL }
        let scheme = url.scheme?.lowercased()
        if scheme == "https" {
            self.baseURL = url
        } else if scheme == "http", Self.allowsInsecureLocalConnection, Self.isPrivateHost(host) {
            self.baseURL = url
        } else {
            throw ServerConfigurationError.insecureScheme
        }
    }

    var displayValue: String { baseURL.absoluteString }

    private static var allowsInsecureLocalConnection: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    static func isPrivateHost(_ host: String) -> Bool {
        let normalized = host.lowercased()
        if normalized == "localhost" || normalized.hasSuffix(".local") { return true }
        let parts = normalized.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4, parts.allSatisfy({ (0 ... 255).contains($0) }) else { return false }
        switch (parts[0], parts[1]) {
        case (127, _), (10, _), (192, 168), (169, 254): return true
        case (172, 16 ... 31): return true
        default: return false
        }
    }
}

@MainActor
@Observable
final class ServerSettingsStore {
    private let storage: UserDefaults
    private let key = "configuredServerURL"
    private(set) var configuration: ServerConfiguration?
    var draftURL: String
    var validationMessage: String?

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        if ProcessInfo.processInfo.environment["UITEST_RESET"] == "1" {
            storage.removeObject(forKey: key)
        }
        let saved = storage.string(forKey: key) ?? ""
        let configuredDefault = Bundle.main.object(forInfoDictionaryKey: "ServerBaseURL") as? String ?? ""
        let initialValue = saved.isEmpty ? configuredDefault : saved
        let parsedConfiguration = try? ServerConfiguration(rawValue: initialValue)
        self.configuration = parsedConfiguration
        self.draftURL = parsedConfiguration?.displayValue ?? ""
    }

    var isConfigured: Bool { configuration != nil }

    func save() {
        do {
            let configuration = try ServerConfiguration(rawValue: draftURL)
            self.configuration = configuration
            storage.set(configuration.displayValue, forKey: key)
            validationMessage = nil
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    func clear() {
        configuration = nil
        draftURL = ""
        validationMessage = nil
        storage.removeObject(forKey: key)
    }
}
