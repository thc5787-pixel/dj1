import SwiftUI

@main
@MainActor
struct DeviceHubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var environment = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(environment)
                .task {
                    appDelegate.pushCoordinator = environment.pushNotifications
                    await environment.auth.restore()
                    await environment.deviceStore.refresh()
                    environment.deviceStore.startMonitoring()
                    await environment.messagesStore.loadContacts()
                    await environment.pushNotifications.refreshAuthorizationStatus()
                }
        }
    }
}
