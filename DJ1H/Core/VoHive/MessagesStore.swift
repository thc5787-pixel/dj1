import Foundation
import Observation

@MainActor
@Observable
final class MessagesStore {
    private let client: VoHiveClient
    private let auth: VoHiveAuthStore
    private(set) var contacts: [VoHiveSMSContact] = []
    private(set) var messages: [VoHiveSMSMessage] = []
    private(set) var isLoadingContacts = false
    private(set) var isLoadingThread = false
    private(set) var isSending = false
    private(set) var errorMessage: String?
    var draft = ""

    init(client: VoHiveClient, auth: VoHiveAuthStore) {
        self.client = client
        self.auth = auth
    }

    func loadContacts() async {
        guard auth.isSignedIn else {
            contacts = []
            errorMessage = nil
            return
        }
        guard !isLoadingContacts else { return }
        isLoadingContacts = true
        defer { isLoadingContacts = false }
        do {
            let loaded = try await client.fetchContacts(deviceID: nil)
            contacts = loaded.sorted {
                (VoHiveDate.parse($0.lastTimestamp) ?? .distantPast) > (VoHiveDate.parse($1.lastTimestamp) ?? .distantPast)
            }
            errorMessage = nil
        } catch VoHiveAPIError.unauthorized {
            auth.handleUnauthorized()
            contacts = []
            errorMessage = VoHiveAPIError.unauthorized.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadThread(for contact: VoHiveSMSContact) async {
        guard auth.isSignedIn else { return }
        isLoadingThread = true
        defer { isLoadingThread = false }
        do {
            let loaded = try await client.fetchThread(peer: contact.peer, deviceID: contact.deviceId, imsi: contact.imsi)
            messages = loaded.sorted {
                (VoHiveDate.parse($0.timestamp) ?? .distantPast) < (VoHiveDate.parse($1.timestamp) ?? .distantPast)
            }
            errorMessage = nil
        } catch VoHiveAPIError.unauthorized {
            auth.handleUnauthorized()
            errorMessage = VoHiveAPIError.unauthorized.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendDraft(to contact: VoHiveSMSContact) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        defer { isSending = false }
        do {
            _ = try await client.sendSMS(
                deviceID: contact.deviceId,
                imsi: contact.imsi,
                phone: contact.peer,
                message: text
            )
            draft = ""
            errorMessage = nil
            await loadThread(for: contact)
            await loadContacts()
        } catch VoHiveAPIError.unauthorized {
            auth.handleUnauthorized()
            errorMessage = VoHiveAPIError.unauthorized.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearThread() {
        messages = []
        draft = ""
        errorMessage = nil
    }
}
