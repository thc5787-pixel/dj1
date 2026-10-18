import SwiftUI

enum AppTheme {
    static let orange = Color(red: 0.94, green: 0.52, blue: 0.14)
    static let green = Color(red: 0.25, green: 0.74, blue: 0.45)
    static let muted = Color.secondary
    static let pageBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let divider = Color(uiColor: .separator).opacity(0.28)
    static let tabBarBackground = Color(uiColor: .secondarySystemBackground)
    static let cardRadius: CGFloat = 26
    static let horizontalPadding: CGFloat = 20
}

struct AppCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.035))
            }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(color)
            .accessibilityLabel("状态：\(text)")
    }
}

struct SignalIndicator: View {
    let level: Int

    private var activeBars: Int {
        guard level > 0 else { return 0 }
        return min(4, max(1, Int(ceil(Double(level) / 25.0))))
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index < activeBars ? Color.primary.opacity(0.7) : Color.primary.opacity(0.15))
                    .frame(width: 4, height: CGFloat(7 + index * 5))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("信号强度")
        .accessibilityValue("\(level)")
    }
}

struct CapabilityRow: View {
    let title: String
    let readiness: CapabilityReadiness

    private var symbol: String {
        switch readiness {
        case .ready: "checkmark.circle.fill"
        case .unavailable: "minus.circle"
        case .configuring: "clock"
        }
    }

    private var color: Color {
        switch readiness {
        case .ready: AppTheme.green
        case .unavailable, .configuring: .secondary
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(title)
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(readiness.title)
    }
}

struct ServiceStatusRow: View {
    let title: String
    let status: ServiceHealth
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer(minLength: 16)
                Text(status.displayText)
                    .foregroundStyle(status.isHealthy ? AppTheme.orange : .secondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 16)
            if showsDivider { Divider().padding(.leading, 0) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(status.displayText)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.orange)
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
