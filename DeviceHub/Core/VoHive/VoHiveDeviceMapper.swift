import Foundation

enum VoHiveDeviceMapper {
    static func snapshot(from devices: [VoHiveDevice]) -> DeviceSnapshot {
        guard let device = devices.first else {
            return DeviceSnapshot(device: nil, state: .disconnected)
        }
        return DeviceSnapshot(device: connectedDevice(from: device), state: connectionState(for: device))
    }

    static func connectedDevice(from device: VoHiveDevice) -> ConnectedDevice {
        let modem = device.modem
        let carrier = modem?.operator.flatMap { $0.isEmpty ? nil : $0 } ?? "未知运营商"
        return ConnectedDevice(
            descriptor: DeviceDescriptor(
                id: device.id,
                displayName: displayName(for: device),
                model: "QDC507"
            ),
            status: DeviceStatus(
                carrier: carrier,
                networkType: modem?.networkMode ?? "",
                signalStrength: signalQuality(from: modem?.signalDbm),
                connection: connectionState(for: device),
                lastUpdated: .now
            ),
            capabilities: DeviceCapabilities(
                sms: device.smsEnabled ? .ready : .unavailable("短信未启用"),
                dialing: .unavailable(VoHiveServiceAvailability.callingReason),
                twoWayAudio: .unavailable(VoHiveServiceAvailability.audioReason)
            )
        )
    }

    static func connectionState(for device: VoHiveDevice) -> DeviceConnectionState {
        if !device.running { return .disconnected }
        if !device.healthy { return .degraded("设备服务异常") }
        if !device.networkConnected { return .degraded("移动网络未连接") }
        return .connected
    }

    static func signalQuality(from dbm: Int?) -> Int {
        guard let dbm, dbm < 0 else { return 0 }
        let clamped = min(-60, max(-110, dbm))
        return Int(((Double(clamped) + 110.0) / 50.0 * 100.0).rounded())
    }

    static func displayName(for device: VoHiveDevice) -> String {
        let name = device.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "DJI / QDC507" }
        return name.localizedCaseInsensitiveContains("DJI") ? name : "DJI / \(name)"
    }
}
