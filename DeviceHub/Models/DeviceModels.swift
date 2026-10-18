import Foundation

enum DeviceConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case degraded(String)
    case unsupported
    case failed(String)

    var title: String {
        switch self {
        case .disconnected: "未连接"
        case .connecting: "正在连接"
        case .connected: "在线"
        case .degraded: "连接异常"
        case .unsupported: "暂不支持"
        case .failed: "连接失败"
        }
    }

    var isHealthy: Bool {
        if case .connected = self { return true }
        return false
    }
}

enum CapabilityReadiness: Equatable, Sendable {
    case ready
    case unavailable(String)
    case configuring

    var title: String {
        switch self {
        case .ready: "已就绪"
        case .unavailable: "未启用"
        case .configuring: "配置中"
        }
    }
}

struct DeviceCapabilities: Equatable, Sendable {
    let sms: CapabilityReadiness
    let dialing: CapabilityReadiness
    let twoWayAudio: CapabilityReadiness
}

struct DeviceDescriptor: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let model: String
}

struct DeviceStatus: Equatable, Sendable {
    let carrier: String
    let networkType: String
    let signalStrength: Int
    let connection: DeviceConnectionState
    let lastUpdated: Date
}

struct ConnectedDevice: Equatable, Sendable {
    let descriptor: DeviceDescriptor
    let status: DeviceStatus
    let capabilities: DeviceCapabilities
}

enum DeviceCommand: Sendable {
    case refreshStatus
}

enum DeviceEvent: Sendable, Equatable {
    case statusChanged(ConnectedDevice)
    case diagnostic(String)
}

struct DeviceSnapshot: Equatable, Sendable {
    let device: ConnectedDevice?
    let state: DeviceConnectionState

    static let empty = DeviceSnapshot(device: nil, state: .disconnected)

    static let preview = DeviceSnapshot(
        device: ConnectedDevice(
            descriptor: DeviceDescriptor(id: "qdc507-demo", displayName: "DJI / QDC507", model: "QDC507"),
            status: DeviceStatus(carrier: "CHN-UNICOM", networkType: "4G", signalStrength: 22, connection: .connected, lastUpdated: .now),
            capabilities: DeviceCapabilities(sms: .ready, dialing: .unavailable("设备侧未启用"), twoWayAudio: .unavailable("设备侧未启用"))
        ),
        state: .connected
    )
}
