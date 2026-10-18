import SwiftUI

struct MessagesView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var showingServerSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if !environment.auth.isSignedIn {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            EmptyStateCard(
                                icon: "message",
                                title: "请先登录 VoHive",
                                message: "登录服务器后才能读取 QDC507 的短信会话。"
                            )
                            Button("打开服务器连接") { showingServerSettings = true }
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.orange)
                        }
                        .padding(AppTheme.horizontalPadding)
                    }
                } else if environment.messagesStore.contacts.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if environment.messagesStore.isLoadingContacts {
                                ProgressView("正在加载短信…")
                                    .frame(maxWidth: .infinity, minHeight: 160)
                            } else {
                                EmptyStateCard(
                                    icon: "message",
                                    title: "暂无短信",
                                    message: "QDC507 收到的短信会显示在这里。下拉可刷新。"
                                )
                            }
                            if let error = environment.messagesStore.errorMessage {
                                Text(error).font(.footnote).foregroundStyle(.red)
                            }
                        }
                        .padding(AppTheme.horizontalPadding)
                    }
                } else {
                    List {
                        ForEach(environment.messagesStore.contacts) { contact in
                            NavigationLink {
                                SMSThreadView(contact: contact)
                            } label: {
                                SMSContactRow(contact: contact)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await environment.messagesStore.loadContacts() }
                }
            }
            .background(AppTheme.pageBackground)
            .navigationTitle("消息")
            .task {
                if environment.messagesStore.contacts.isEmpty {
                    await environment.messagesStore.loadContacts()
                }
            }
            .refreshable { await environment.messagesStore.loadContacts() }
            .sheet(isPresented: $showingServerSettings) {
                ServerConnectionView().environment(environment)
            }
        }
    }
}

private struct SMSContactRow: View {
    let contact: VoHiveSMSContact

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(AppTheme.orange.opacity(0.85))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.peer).font(.headline)
                    Spacer()
                    Text(VoHiveDate.shortDisplay(contact.lastTimestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(contact.lastContent ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if let unread = contact.unreadCount, unread > 0 {
                        Text("\(unread)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.orange, in: Capsule())
                    }
                }
                if let device = contact.deviceName, !device.isEmpty {
                    Text(device).font(.caption2).foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
