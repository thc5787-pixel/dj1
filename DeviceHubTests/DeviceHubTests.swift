import XCTest
@testable import DeviceHub

final class DeviceHubTests: XCTestCase {
    func testServerConfigurationAcceptsHTTPS() throws {
        let configuration = try ServerConfiguration(rawValue: "https://server.example.com/api")
        XCTAssertEqual(configuration.baseURL.host, "server.example.com")
    }

    #if DEBUG
    func testServerConfigurationAcceptsPrivateHTTPInDebug() throws {
        let configuration = try ServerConfiguration(rawValue: "http://192.168.64.3:7575")
        XCTAssertEqual(configuration.baseURL.host, "192.168.64.3")
    }
    #endif

    func testServerConfigurationRejectsPublicHTTP() {
        XCTAssertThrowsError(try ServerConfiguration(rawValue: "http://server.example.com")) { error in
            XCTAssertEqual(error as? ServerConfigurationError, .insecureScheme)
        }
    }

    func testServerConfigurationRejectsInvalidURL() {
        XCTAssertThrowsError(try ServerConfiguration(rawValue: "not a url"))
    }

    @MainActor
    func testServerSettingsPersistValidation() {
        let defaults = UserDefaults(suiteName: "DeviceHubTests.\(UUID().uuidString)")!
        let store = ServerSettingsStore(storage: defaults)
        store.draftURL = "http://public.example.com"
        store.save()
        XCTAssertNil(store.configuration)
        XCTAssertNotNil(store.validationMessage)
        store.draftURL = "https://valid.example.com"
        store.save()
        XCTAssertEqual(store.configuration?.baseURL.host, "valid.example.com")
        store.clear()
        XCTAssertNil(store.configuration)
    }

    func testPreviewSnapshotIsConnectedWithHonestCapabilities() throws {
        let device = try XCTUnwrap(DeviceSnapshot.preview.device)
        XCTAssertEqual(device.status.connection, .connected)
        XCTAssertEqual(device.capabilities.sms, .ready)
        XCTAssertEqual(device.capabilities.twoWayAudio, .unavailable("设备侧未启用"))
    }

    func testAPNSTokenHexEncoding() {
        let data = Data([0x00, 0x0a, 0xff, 0x12])
        XCTAssertEqual(PushNotificationCoordinator.hexString(from: data), "000aff12")
    }

    func testVoHiveDeviceMapping() throws {
        let json = """
        {
          "devices": [{
            "id": "dev-1",
            "name": "QDC507",
            "running": true,
            "healthy": true,
            "control_online": true,
            "sms_enabled": true,
            "network_enabled": true,
            "network_connected": true,
            "registration_state_label": "registered",
            "modem": {
              "operator": "CHN-UNICOM",
              "signal_dbm": -70,
              "network_mode": "LTE"
            }
          }]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(VoHiveDeviceListResponse.self, from: json)
        let snapshot = VoHiveDeviceMapper.snapshot(from: response.devices)
        let device = try XCTUnwrap(snapshot.device)
        XCTAssertEqual(device.descriptor.displayName, "DJI / QDC507")
        XCTAssertEqual(device.status.carrier, "CHN-UNICOM")
        XCTAssertEqual(device.status.signalStrength, 80)
        XCTAssertEqual(device.status.connection, .connected)
        XCTAssertEqual(device.capabilities.sms, .ready)
        XCTAssertEqual(device.capabilities.dialing, .unavailable(VoHiveServiceAvailability.callingReason))
    }

    func testVoHiveClientLoginAndAuthenticatedRequest() async throws {
        let session = makeStubSession { request in
            guard let url = request.url else { throw TestError.invalidRequest }
            switch url.path {
            case "/api/auth/login":
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
                return (200, ["status": "ok", "token": "token-123", "expires_at": "2026-12-01T00:00:00Z"])
            case "/api/devices":
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")
                return (200, [
                    "devices": []
                ])
            default:
                throw TestError.unexpectedPath(url.path)
            }
        }
        let client = VoHiveClient(session: session)
        await client.configure(baseURL: try XCTUnwrap(URL(string: "http://127.0.0.1:7575")), token: nil)
        let login = try await client.login(username: "admin", password: "secret")
        XCTAssertEqual(login.token, "token-123")
        let devices = try await client.fetchDevices()
        XCTAssertTrue(devices.isEmpty)
    }

    func testVoHiveClientMapsUnauthorized() async throws {
        let session = makeStubSession { _ in (401, ["error": "invalid token"]) }
        let client = VoHiveClient(session: session)
        await client.configure(baseURL: try XCTUnwrap(URL(string: "http://127.0.0.1:7575")), token: "expired")
        do {
            _ = try await client.fetchDevices()
            XCTFail("Expected unauthorized")
        } catch {
            XCTAssertEqual(error as? VoHiveAPIError, .unauthorized)
        }
    }

    private func makeStubSession(
        handler: @escaping @Sendable (URLRequest) throws -> (Int, [String: Any])
    ) -> URLSession {
        StubURLProtocol.handler = { request in
            let (status, payload) = try handler(request)
            let data = try JSONSerialization.data(withJSONObject: payload)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
            return (response, data)
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private enum TestError: Error {
    case invalidRequest
    case unexpectedPath(String)
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: TestError.invalidRequest)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
