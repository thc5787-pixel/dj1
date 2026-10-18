import SwiftUI

struct RootTabView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment
        TabView(selection: $environment.selectedTab) {
            MessagesView()
                .tabItem { Label("消息", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.messages)
            CallsView()
                .tabItem { Label("电话", systemImage: "phone.fill") }
                .tag(AppTab.calls)
            AssistantView()
                .tabItem { Label("助理", systemImage: "sparkles") }
                .tag(AppTab.assistant)
            DeviceDashboardView()
                .tabItem { Label("设备", systemImage: "antenna.radiowaves.left.and.right") }
                .tag(AppTab.devices)
        }
        .tint(AppTheme.orange)
        .accessibilityIdentifier("rootTabView")
    }
}
