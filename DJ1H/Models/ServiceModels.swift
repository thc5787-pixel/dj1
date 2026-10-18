import Foundation

enum ServiceHealth: Equatable, Sendable {
    case active(String)
    case unconfigured
    case unavailable(String)
    case checking

    var displayText: String {
        switch self {
        case let .active(text), let .unavailable(text): text
        case .unconfigured: "未配置"
        case .checking: "检查中"
        }
    }

    var isHealthy: Bool {
        if case .active = self { return true }
        return false
    }
}

struct ServiceOverview: Equatable, Sendable {
    let realtimeConnection: ServiceHealth
    let ai: ServiceHealth
    let remotePush: ServiceHealth
}

enum PushAuthorizationStatus: Equatable, Sendable {
    case undetermined
    case denied
    case authorized
    case provisional
    case unsupported

    var title: String {
        switch self {
        case .undetermined: "尚未授权"
        case .denied: "已拒绝"
        case .authorized: "已授权"
        case .provisional: "临时授权"
        case .unsupported: "不可用"
        }
    }
}

enum PushRegistrationState: Equatable, Sendable {
    case idle
    case registering
    case registered
    case failed(String)

    var title: String {
        switch self {
        case .idle: "未注册"
        case .registering: "注册中"
        case .registered: "已注册"
        case .failed: "注册失败"
        }
    }
}
