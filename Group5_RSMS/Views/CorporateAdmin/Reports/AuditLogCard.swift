// AuditLogCard.swift
// Group5_RSMS — Reusable card for audit log list row (inside Reports)

import SwiftUI

struct AuditLogCard: View {
    let log: AuditLog

    // Color per action type
    private var actionColor: Color {
        switch log.actionType {
        case .created: return RSMSTheme.Colors.success
        case .updated: return RSMSTheme.Colors.accentGold
        case .deleted: return RSMSTheme.Colors.error
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Icon Badge
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: log.eventType.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Action title + action type badge in one row
                HStack(spacing: 6) {
                    Text(log.action)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Action type pill (Created / Updated / Deleted)
                    HStack(spacing: 3) {
                        Image(systemName: log.actionType.iconName)
                            .font(.system(size: 9, weight: .bold))
                        Text(log.actionType.rawValue)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(actionColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(actionColor.opacity(0.12))
                    .cornerRadius(50)
                }

                Text(log.entity)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 11))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Text(log.userName)
                        .font(.system(size: 11))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, 1)
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}
