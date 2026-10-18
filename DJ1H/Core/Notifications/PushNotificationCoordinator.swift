import Foundation
import Observation
import UIKit
import UserNotifications

@MainActor
@Observable
final class PushNotificationCoordinator {
    private(set) var authorizationStatus: PushAuthorizationStatus = .undetermined
    private(set) var registrationState: PushRegistrationState = .idle
    private(set) var deviceToken: String?

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = Self.makeAuthorizationStatus(settings.authorizationStatus)
        if authorizationStatus == .authorized || authorizationStatus == .provisional {
            registerForRemoteNotifications()
        }
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
        } catch {
            registrationState = .failed("无法请求通知权限")
        }
    }

    func registerForRemoteNotifications() {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
        registrationState = .registering
        UIApplication.shared.registerForRemoteNotifications()
    }

    func didRegister(deviceToken data: Data) {
        deviceToken = Self.hexString(from: data)
        registrationState = .registered
        // Backend upload remains intentionally inactive until its endpoint and authentication contract exist.
    }

    func didFailToRegister(error: Error) {
        registrationState = .failed("未能完成推送注册")
    }

    nonisolated static func hexString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private static func makeAuthorizationStatus(_ status: UNAuthorizationStatus) -> PushAuthorizationStatus {
        switch status {
        case .notDetermined: .undetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        case .ephemeral: .authorized
        @unknown default: .unsupported
        }
    }
}
