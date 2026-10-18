import Foundation
import Observation

@MainActor
@Observable
final class DeviceStore {
    private let client: VoHiveClient
    private let auth: VoHiveAuthStore
    private(set) var snapshot: DeviceSnapshot = .empty
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastRefreshedAt: Date?
    private var monitoringTask: Task<Void, Never>?

    init(client: VoHiveClient, auth: VoHiveAuthStore) {
        self.client = client
        self.auth = auth
    }

    func startMonitoring() {
        guard monitoringTask == nil else { return }
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                try? await Task.sleep(for: .seconds(20))
            }
        }
    }

    func refresh() async {
        guard auth.isSignedIn else {
            snapshot = .empty
            errorMessage = nil
            return
        }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let devices = try await client.fetchDevices()
            snapshot = VoHiveDeviceMapper.snapshot(from: devices)
            errorMessage = nil
            lastRefreshedAt = .now
        } catch VoHiveAPIError.unauthorized {
            auth.handleUnauthorized()
            snapshot = .empty
            errorMessage = VoHiveAPIError.unauthorized.localizedDescription
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            if let device = snapshot.device {
                let failedStatus = DeviceStatus(
                    carrier: device.status.carrier,
                    networkType: device.status.networkType,
                    signalStrength: device.status.signalStrength,
                    connection: .failed(message),
                    lastUpdated: device.status.lastUpdated
                )
                snapshot = DeviceSnapshot(
                    device: ConnectedDevice(descriptor: device.descriptor, status: failedStatus, capabilities: device.capabilities),
                    state: .failed(message)
                )
            } else {
                snapshot = DeviceSnapshot(device: nil, state: .failed(message))
            }
        }
    }
}
