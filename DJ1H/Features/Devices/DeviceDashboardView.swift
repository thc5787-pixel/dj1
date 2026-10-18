import SwiftUI

struct DeviceDashboardView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var showingServerSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    connectedDeviceSection
                    serviceSection
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageBackground)
            .toolbar(.hidden, for: .navigationBar)
            .refreshable { await environment.deviceStore.refresh() }
        }
        .sheet(isPresented: $showingServerSettings) {
            ServerConnectionView()
                .environment(environment)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text("设备")
                .font(.system(size: 40, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button {
                showingServerSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.cardBackground)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
                    Image(systemName: "record.circle")
                        .font(.system(size: 27, weight: .medium))
                }
                .foregroundStyle(AppTheme.orange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("管理服务器连接")
            .accessibilityIdentifier("serverSettingsButton")
        }
        .padding(.top, 20)
    }

    private var connectedDeviceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("已接入设备")
                .font(.title3)
                .foregroundStyle(.secondary)
            if let device = environment.deviceStore.snapshot.device {
                DeviceCard(device: device)
                    .accessibilityIdentifier("connectedDeviceCard")
                if let error = environment.deviceStore.errorMessage {
                    errorBanner(error)
                }
            } else if environment.deviceStore.isLoading {
                AppCard {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("正在读取设备状态…").foregroundStyle(.secondary)
                    }
                }
            } else {
                if let error = environment.deviceStore.errorMessage {
                    errorBanner(error)
                }
                EmptyStateCard(
                    icon: "antenna.radiowaves.left.and.right",
                    title: environment.deviceStore.errorMessage == nil ? emptyStateTitle : "无法读取设备",
                    message: environment.deviceStore.errorMessage == nil ? emptyStateMessage : "请检查服务器连接与登录状态，然后重试。"
                )
                Button("打开服务器连接") {
                    showingServerSettings = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.orange)
                .accessibilityIdentifier("connectServerButton")
            }
        }
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("服务状态")
                .font(.title3)
                .foregroundStyle(.secondary)
            AppCard {
                VStack(spacing: 0) {
                    ServiceStatusRow(
                        title: "连接",
                        status: connectionHealth
                    )
                    ServiceStatusRow(title: "AI 服务", status: .unconfigured)
                    ServiceStatusRow(title: "远程推送", status: pushHealth, showsDivider: false)
                    Text("App 在后台时的通知和来电，需要服务器配置 Apple 推送服务。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                    Divider()
                    Button {
                        showingServerSettings = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .font(.title3)
                            Text("管理服务器连接")
                                .font(.title3)
                        }
                        .foregroundStyle(AppTheme.orange)
                        .padding(.top, 18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("manageServerConnectionButton")
                }
            }
        }
    }

    private var connectionHealth: ServiceHealth {
        guard environment.auth.isSignedIn else { return .unconfigured }
        if environment.deviceStore.snapshot.state.isHealthy { return .active("实时连接") }
        return .unavailable("未连接")
    }

    private var pushHealth: ServiceHealth {
        switch environment.pushNotifications.registrationState {
        case .registered:
            switch environment.pushNotifications.authorizationStatus {
            case .authorized, .provisional: .unavailable("未上报")
            default: .unavailable("未授权")
            }
        case .registering: .checking
        case .failed: .unavailable("注册失败")
        case .idle: .unconfigured
        }
    }

    private var emptyStateTitle: String {
        switch environment.auth.state {
        case .unconfigured: "尚未配置 VoHive 服务器"
        case .signedOut, .failed: "请登录 VoHive 服务器"
        case .signingIn: "正在登录"
        case .signedIn: "服务器上暂无设备"
        }
    }

    private var emptyStateMessage: String {
        switch environment.auth.state {
        case .unconfigured: "配置已部署的 VoHive 服务后，即可读取 DJI 4G 模块状态与短信。"
        case .signedOut, .failed: "完成登录后，设备在线状态、运营商、信号与短信能力会显示在这里。"
        case .signingIn: "正在验证服务器凭据。"
        case .signedIn: "VoHive 已连接，但没有发现可管理的 QDC507 模块。"
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Button("重试") {
                Task { await environment.deviceStore.refresh() }
            }
            .font(.footnote.weight(.semibold))
        }
        .padding(14)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DeviceCard: View {
    let device: ConnectedDevice

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppTheme.orange)
                        .frame(width: 38, height: 38)
                        .accessibilityHidden(true)
                    Text(device.descriptor.displayName)
                        .font(.title2.weight(.semibold))
                    Spacer(minLength: 8)
                    StatusBadge(text: device.status.connection.title, color: device.status.connection.isHealthy ? AppTheme.green : .secondary)
                }

                HStack(alignment: .center) {
                    Text(device.status.carrier)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                    SignalIndicator(level: device.status.signalStrength)
                    Text("\(device.status.signalStrength)")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 26) {
                    CapabilityRow(title: "短信", readiness: device.capabilities.sms)
                    CapabilityRow(title: "拨号", readiness: device.capabilities.dialing)
                    CapabilityRow(title: "双向语音", readiness: device.capabilities.twoWayAudio)
                }

                Text(capabilitySummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var capabilitySummary: String {
        var parts: [String] = []
        if device.capabilities.sms == .ready { parts.append("短信已就绪") }
        if case .unavailable = device.capabilities.dialing { parts.append("拨号需服务端支持") }
        if case .unavailable = device.capabilities.twoWayAudio { parts.append("双向语音需服务端支持") }
        return parts.isEmpty ? "等待设备能力上报。" : parts.joined(separator: "；")
    }
}
