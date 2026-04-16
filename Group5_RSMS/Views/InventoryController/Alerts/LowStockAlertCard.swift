//
//  LowStockAlertCard.swift
//  Group5_RSMS
//
//  Luxury card component for displaying a low-stock alert.
//  Shows product name, SKU, quantity (in error red), and store location.
//

import SwiftUI

struct LowStockAlertCard: View {
    let alert: LowStockAlert

    /// Severity color — critical (0-1) vs warning (2-4)
    private var quantityColor: Color {
        alert.stockQuantity <= 1
            ? RSMSTheme.Colors.error
            : RSMSTheme.Colors.warning
    }

    private var severityLabel: String {
        alert.stockQuantity == 0 ? "OUT OF STOCK" : "LOW STOCK"
    }

    private var severityIcon: String {
        alert.stockQuantity == 0
            ? "xmark.octagon.fill"
            : "exclamationmark.triangle.fill"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // Quantity Badge
            VStack(spacing: 2) {
                Text("\(alert.stockQuantity)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(quantityColor)
                Text("left")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(quantityColor.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .fill(quantityColor.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                            .stroke(quantityColor.opacity(0.25), lineWidth: 1)
                    )
            )

            // Content
            VStack(alignment: .leading, spacing: 5) {
                // Product name
                Text(alert.productName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)

                // SKU
                Text(alert.productSku)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .lineLimit(1)

                // Store location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                    Text("\(alert.storeName) · \(alert.storeCity)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Severity badge + chevron
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 3) {
                    Image(systemName: severityIcon)
                        .font(.system(size: 8, weight: .bold))
                    Text(severityLabel)
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.4)
                }
                .foregroundColor(quantityColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(quantityColor.opacity(0.12))
                .cornerRadius(50)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.accentGoldDark.opacity(0.5))
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(quantityColor.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}
