import Foundation

enum VoHiveAPIError: LocalizedError, Equatable {
    case notConfigured
    case notAuthenticated
    case unauthorized
    case server(String)
    case invalidResponse
    case decoding
    case transport

    var errorDescription: String? {
        switch self {
        case .notConfigured: "请先在设置中配置 VoHive 服务器地址。"
        case .notAuthenticated: "请先登录 VoHive 服务器。"
        case .unauthorized: "登录已失效，请重新登录。"
        case let .server(message): message
        case .invalidResponse: "服务器响应无效。"
        case .decoding: "无法读取服务器响应。"
        case .transport: "无法连接到 VoHive 服务器。"
        }
    }
}

actor VoHiveClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var baseURL: URL?
    private var token: String?

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func configure(baseURL: URL, token: String?) {
        self.baseURL = baseURL
        self.token = token
    }

    func setToken(_ token: String?) {
        self.token = token
    }

    func login(username: String, password: String) async throws -> VoHiveLoginResponse {
        let body = try encoder.encode(LoginBody(username: username, password: password))
        let response: VoHiveLoginResponse = try await send(
            path: "auth/login",
            method: "POST",
            body: body,
            requiresAuthentication: false
        )
        token = response.token
        return response
    }

    func fetchDevices() async throws -> [VoHiveDevice] {
        let response: VoHiveDeviceListResponse = try await send(path: "devices")
        return response.devices
    }

    func fetchContacts(deviceID: String?) async throws -> [VoHiveSMSContact] {
        var query: [URLQueryItem] = [URLQueryItem(name: "limit", value: "100")]
        if let deviceID { query.append(URLQueryItem(name: "device_id", value: deviceID)) }
        return try await send(path: "sms/contacts", query: query)
    }

    func fetchThread(peer: String, deviceID: String?, imsi: String?, limit: Int = 100) async throws -> [VoHiveSMSMessage] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "peer", value: peer),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let deviceID { query.append(URLQueryItem(name: "device_id", value: deviceID)) }
        if let imsi { query.append(URLQueryItem(name: "imsi", value: imsi)) }
        return try await send(path: "sms/thread", query: query)
    }

    func sendSMS(deviceID: String?, imsi: String?, phone: String, message: String) async throws -> VoHiveSendSMSResponse {
        let body = try encoder.encode(VoHiveSendSMSRequest(deviceId: deviceID, imsi: imsi, phone: phone, message: message))
        return try await send(path: "sms/send", method: "POST", body: body)
    }

    private func send<Response: Decodable>(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        requiresAuthentication: Bool = true
    ) async throws -> Response {
        guard let baseURL else { throw VoHiveAPIError.notConfigured }
        guard !requiresAuthentication || token != nil else { throw VoHiveAPIError.notAuthenticated }

        guard var components = URLComponents(
            url: baseURL.appending(path: "api").appending(path: path),
            resolvingAgainstBaseURL: false
        ) else { throw VoHiveAPIError.notConfigured }
        if !query.isEmpty {
            components.percentEncodedQuery = query.map { item in
                "\(Self.encodeQueryComponent(item.name))=\(Self.encodeQueryComponent(item.value ?? ""))"
            }.joined(separator: "&")
        }
        guard let url = components.url else { throw VoHiveAPIError.notConfigured }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if requiresAuthentication, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw VoHiveAPIError.invalidResponse }
            guard (200 ... 299).contains(http.statusCode) else {
                if http.statusCode == 401 { throw VoHiveAPIError.unauthorized }
                let payload = try? decoder.decode(VoHiveErrorPayload.self, from: data)
                throw VoHiveAPIError.server(payload?.error ?? payload?.message ?? "服务器返回错误（\(http.statusCode)）。")
            }
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw VoHiveAPIError.decoding
            }
        } catch let error as VoHiveAPIError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw VoHiveAPIError.transport
        }
    }
}

private extension VoHiveClient {
    static func encodeQueryComponent(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
}

private struct LoginBody: Encodable {
    let username: String
    let password: String
}
