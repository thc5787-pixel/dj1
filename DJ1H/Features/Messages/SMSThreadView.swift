import SwiftUI

struct SMSThreadView: View {
    @Environment(AppEnvironment.self) private var environment
    let contact: VoHiveSMSContact

    var body: some View {
        @Bindable var store = environment.messagesStore
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(environment.messagesStore.messages) { message in
                            SMSBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .background(AppTheme.pageBackground)
                .refreshable { await environment.messagesStore.loadThread(for: contact) }
                .onChange(of: environment.messagesStore.messages.count) {
                    if let last = environment.messagesStore.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if let error = environment.messagesStore.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("输入短信", text: $store.draft, axis: .vertical)
                    .lineLimit(1 ... 5)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityIdentifier("smsDraftField")
                Button {
                    Task { await environment.messagesStore.sendDraft(to: contact) }
                } label: {
                    Image(systemName: environment.messagesStore.isSending ? "clock" : "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(canSend ? AppTheme.orange : Color.secondary.opacity(0.4))
                }
                .disabled(!canSend)
                .accessibilityLabel("发送短信")
                .accessibilityIdentifier("sendSMSButton")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.bar)
        }
        .navigationTitle(contact.peer)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            environment.messagesStore.clearThread()
            await environment.messagesStore.loadThread(for: contact)
        }
    }

    private var canSend: Bool {
        !environment.messagesStore.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !environment.messagesStore.isSending
    }
}

private struct SMSBubble: View {
    let message: VoHiveSMSMessage

    var body: some View {
        HStack {
            if !message.isInbound { Spacer(minLength: 46) }
            VStack(alignment: message.isInbound ? .leading : .trailing, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(message.isInbound ? Color.primary : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isInbound ? AppTheme.cardBackground : AppTheme.orange,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                HStack(spacing: 4) {
                    Text(VoHiveDate.shortDisplay(message.timestamp))
                    if !message.isInbound {
                        switch message.status {
                        case 2: Text("· 已发送")
                        case 3: Text("· 发送失败").foregroundStyle(.red)
                        default: EmptyView()
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            if message.isInbound { Spacer(minLength: 46) }
        }
        .accessibilityElement(children: .combine)
    }
}
