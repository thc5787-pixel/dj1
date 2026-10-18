import SwiftUI

struct CallsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    EmptyStateCard(
                        icon: "phone.down",
                        title: "通话功能待服务端接入",
                        message: "VoHive 当前只提供设备与短信 API，尚未提供拨号、接听和双向音频接口，因此 App 不会虚假触发通话。"
                    )
                    if let device = environment.deviceStore.snapshot.device {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("当前模块").font(.headline)
                            Text(device.descriptor.displayName)
                            Text(device.capabilities.dialing.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    Text("QDC507 的通话还需要服务端完成 QMI/AT 呼叫控制与 USB Audio 音频桥接，再通过 HTTP/WebSocket 提供给 iOS。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(AppTheme.horizontalPadding)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("电话")
        }
    }
}
