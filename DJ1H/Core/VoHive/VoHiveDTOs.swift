import Foundation

struct VoHiveLoginResponse: Decodable, Sendable {
    let status: String
    let token: String
    let expiresAt: String?
}

struct VoHiveDeviceListResponse: Decodable, Sendable {
    let devices: [VoHiveDevice]
}

struct VoHiveDevice: Decodable, Sendable, Equatable {
    let id: String
    let name: String
    let running: Bool
    let healthy: Bool
    let controlOnline: Bool
    let smsEnabled: Bool
    let networkEnabled: Bool
    let networkConnected: Bool
    let registrationStateLabel: String?
    let publicIp: String?
    let modem: VoHiveModem?
}

struct VoHiveModem: Decodable, Sendable, Equatable {
    let imei: String?
    let firmware: String?
    let iccid: String?
    let imsi: String?
    let `operator`: String?
    let signalDbm: Int?
    let signalRsrp: Int?
    let signalRsrq: Int?
    let networkMode: String?
    let regStatusText: String?
}

struct VoHiveSMSContact: Decodable, Sendable, Identifiable, Equatable {
    let imsi: String?
    let peer: String
    let lastSmsId: Int?
    let lastTimestamp: String?
    let lastContent: String?
    let lastType: Int?
    let unreadCount: Int?
    let deviceId: String?
    let deviceName: String?
    let localPhone: String?

    var id: String { "\(deviceId ?? "")-\(imsi ?? "")-\(peer)" }
}

struct VoHiveSMSMessage: Decodable, Sendable, Identifiable, Equatable {
    let id: Int
    let imsi: String?
    let peer: String?
    let localPhone: String?
    let sender: String?
    let recipient: String?
    let content: String
    let type: Int
    let status: Int?
    let timestamp: String?
    let deviceName: String?

    var isInbound: Bool { type == 1 }
}

struct VoHiveSendSMSRequest: Encodable, Sendable {
    let deviceId: String?
    let imsi: String?
    let phone: String
    let message: String
}

struct VoHiveSendSMSResponse: Decodable, Sendable {
    let status: String
    let message: String?
    let device: String?
    let phone: String?
    let messageId: String?
    let partsTotal: Int?
    let deliveryState: String?
}

struct VoHiveErrorPayload: Decodable, Sendable {
    let error: String?
    let message: String?
    let status: String?
}

enum VoHiveServiceAvailability {
    static let callingReason = "VoHive 服务端尚未提供通话接口"
    static let audioReason = "VoHive 服务端尚未提供语音音频通道"
    static let pushReason = "VoHive 服务端尚未提供 APNs 注册接口"
}
