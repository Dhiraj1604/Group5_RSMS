import SwiftUI

struct OfferStatusPill: View {
    let status: OfferStatus

    private var config: (label: String, fg: Color, bg: Color) {
        switch status {
        case .active:
            return ("Active", RSMSTheme.Colors.success, RSMSTheme.Colors.success.opacity(0.1))
        case .scheduled:
            return ("Scheduled", RSMSTheme.Colors.warning, RSMSTheme.Colors.warning.opacity(0.1))
        case .expired:
            return ("Expired", RSMSTheme.Colors.textSecondary, RSMSTheme.Colors.textSecondary.opacity(0.1))
        case .paused:
            return ("Paused", RSMSTheme.Colors.warning, RSMSTheme.Colors.warning.opacity(0.1))
        }
    }

    var body: some View {
        Text(config.label.uppercased())
            .font(.custom("Helvetica", size: 10).weight(.bold))
            .tracking(0.8)
            .foregroundColor(config.fg)
            .padding(.horizontal, RSMSTheme.Spacing.sm)
            .padding(.vertical, RSMSTheme.Spacing.xs)
            .background(config.bg)
            .cornerRadius(RSMSTheme.Radius.md)
            .overlay(
                Capsule()
                    .stroke(config.fg.opacity(0.3), lineWidth: 0.5)
            )
    }
}
