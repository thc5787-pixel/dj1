import Foundation
import Observation

@MainActor
@Observable
final class AppEnvironment {
    let deviceStore: DeviceStore
    let messagesStore: MessagesStore
    let serverSettings: ServerSettingsStore
    let auth: VoHiveAuthStore
    let pushNotifications: PushNotificationCoordinator
    var selectedTab: AppTab = .devices

    init(
        deviceStore: DeviceStore,
        messagesStore: MessagesStore,
        serverSettings: ServerSettingsStore,
        auth: VoHiveAuthStore,
        pushNotifications: PushNotificationCoordinator
    ) {
        self.deviceStore = deviceStore
        self.messagesStore = messagesStore
        self.serverSettings = serverSettings
        self.auth = auth
        self.pushNotifications = pushNotifications
    }

    static func live() -> AppEnvironment {
        let settings = ServerSettingsStore()
        let client = VoHiveClient()
        let auth = VoHiveAuthStore(client: client, serverSettings: settings)
        return AppEnvironment(
            deviceStore: DeviceStore(client: client, auth: auth),
            messagesStore: MessagesStore(client: client, auth: auth),
            serverSettings: settings,
            auth: auth,
            pushNotifications: PushNotificationCoordinator()
        )
    }
}

enum AppTab: Hashable {
    case messages
    case calls
    case assistant
    case devices
}
