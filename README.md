# DJ1H

DJ1H is a native Chinese-first iPhone client for managing the first-generation DJI 4G module (Baiwang/Quectel QDC507) through a VoHive/openvohive server.

An iPhone cannot control a QDC507 directly: the module exposes USB serial/AT, QMI and ADB interfaces over USB-C, and its call audio requires host-side drivers. The app therefore talks to VoHive, which owns the USB device and exposes device status and SMS over its authenticated HTTP API.

## Prerequisites

- Xcode with an iOS 27 SDK and Simulator runtime
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- An Apple Developer Team and a unique bundle identifier before using APNs on hardware

## Open the project

```sh
xcodegen generate
open DJ1H.xcodeproj
```

Select an Apple Developer Team in Xcode and replace `com.example.devicehub` with your registered identifier. Push Notifications capability is declared for local APNs registration; actual remote delivery still requires a server-side APNs sender.

## Current implementation status

- Server URL, username and password login against VoHive's `POST /api/auth/login`; the bearer token is stored in Keychain and the password is never persisted.
- Device status is read from `GET /api/devices` and polled every 20 seconds while the app is active.
- SMS conversations, message history and sending use `/api/sms/contacts`, `/api/sms/thread` and `/api/sms/send`.
- Dialing, two-way audio and AI remain unavailable because the open-source VoHive API does not expose those endpoints.
- APNs authorization and token registration are implemented locally, but token upload is not: VoHive has no APNs registration endpoint yet.
- Debug builds accept `http://` only for private/local hosts. Release builds require HTTPS.

## Integration boundaries

- `Core/VoHive/VoHiveClient.swift` is the HTTP boundary for authentication, device status and SMS.
- `Core/VoHive/VoHiveAuthStore.swift` owns login state and Keychain-backed token storage.
- `Core/VoHive/DeviceStore.swift` and `VoHiveDeviceMapper.swift` convert VoHive device payloads into UI state.
- `Core/VoHive/MessagesStore.swift` owns SMS conversations and sending.
- Bluetooth, local-network, microphone, and background-audio permissions are deliberately absent because the phone talks to the server rather than the module.

## Test

```sh
xcodebuild test -project DJ1H.xcodeproj -scheme DJ1H -destination 'platform=iOS Simulator,name=iPhone 17'
```

APNs registration must be checked on a physical device; Simulator execution is not evidence of push entitlement or delivery correctness.
