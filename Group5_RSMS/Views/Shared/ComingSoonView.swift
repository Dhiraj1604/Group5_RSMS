//
//  ComingSoonView.swift
//  Group5_RSMS
//
//  Sprint 1 — Reusable placeholder for features not yet implemented.
//

import SwiftUI

struct ComingSoonView: View {
    let title: String
    let icon: String
    let description: String

    init(title: String, icon: String = "hammer.fill", description: String = "This feature is coming in a future sprint.") {
        self.title = title
        self.icon = icon
        self.description = description
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: RSMSTheme.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.6))
                }

                VStack(spacing: RSMSTheme.Spacing.sm) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Text("COMING SOON")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.vertical, RSMSTheme.Spacing.sm)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(RSMSTheme.Spacing.xxl)
        }
    }
}

#Preview {
    ComingSoonView(title: "Products", icon: "tag.fill")
}
