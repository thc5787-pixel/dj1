import SwiftUI

struct ServerConnectionView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = environment.serverSettings
        @Bindable var auth = environment.auth
        NavigationStack {
            Form {
                Section {
                    TextField("https://vohive.example.com", text: $settings.draftURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("serverURLField")
                } header: {
                    Text("VoHive 服务器")
                    if settings.isConfigured {
                        Button("清除服务器地址", role: .destructive) {
                            settings.clear()
                            auth.logout()
                            Task {
                                await environment.deviceStore.refresh()
                                await environment.messagesStore.loadContacts()
                            }
                        }
                    }
                } footer: {
                    if let message = settings.validationMessage {
                        Text(message).foregroundStyle(.red)
                    } else {
                        Text("输入已部署的 VoHive 地址。Debug 构建允许使用局域网 HTTP 地址；生产环境仅接受 HTTPS。")
                    }
                }

                Section {
                    TextField("用户名", text: $auth.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("usernameField")
                    SecureField("密码", text: $auth.password)
                        .textContentType(.password)
                        .accessibilityIdentifier("passwordField")
                    LabeledContent("状态", value: auth.state.title)
                    if case let .failed(message) = auth.state {
                        Text(message).font(.footnote).foregroundStyle(.red)
                    }
                    Button {
                        connect()
                    } label: {
                        Text(auth.isSignedIn ? "重新登录" : "保存并登录")
                    }
                    .disabled(auth.state == .signingIn)
                    .accessibilityIdentifier("loginButton")
                    if auth.isSignedIn {
                        Button("退出登录", role: .destructive) {
                            auth.logout()
                            Task {
                                await environment.deviceStore.refresh()
                                await environment.messagesStore.loadContacts()
                            }
                        }
                    }
                } header: {
                    Text("账户")
                } footer: {
                    Text("密码仅用于本次登录，不会保存在本机；登录 token 保存在 Keychain。")
                }

                Section("通知") {
                    LabeledContent("权限", value: environment.pushNotifications.authorizationStatus.title)
                    LabeledContent("设备注册", value: environment.pushNotifications.registrationState.title)
                    if environment.pushNotifications.authorizationStatus == .undetermined {
                        Button("启用远程通知") {
                            Task { await environment.pushNotifications.requestAuthorization() }
                        }
                    } else if environment.pushNotifications.authorizationStatus == .authorized {
                        Button("重新注册推送") {
                            environment.pushNotifications.registerForRemoteNotifications()
                        }
                    }
                    Text(VoHiveServiceAvailability.pushReason + "，因此暂无法把 token 上报到服务器。")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("通话与语音") {
                    Text(VoHiveServiceAvailability.callingReason + "。")
                    Text(VoHiveServiceAvailability.audioReason + "。")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("服务器连接")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func connect() {
        environment.serverSettings.save()
        environment.auth.serverConfigurationChanged()
        guard environment.serverSettings.validationMessage == nil,
              environment.serverSettings.isConfigured else { return }
        Task {
            await environment.auth.login()
            await environment.deviceStore.refresh()
            await environment.messagesStore.loadContacts()
        }
    }
}
