import SwiftUI

struct AssistantView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    EmptyStateCard(
                        icon: "sparkles",
                        title: "AI 服务未接入",
                        message: "VoHive 当前 API 未提供 AI 服务接口。接入模型服务后，可在这里提供设备状态解读与短信助理。"
                    )
                    if environment.auth.isSignedIn {
                        LabeledContent("VoHive", value: "已登录")
                            .padding(18)
                            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(AppTheme.horizontalPadding)
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("助理")
        }
    }
}
