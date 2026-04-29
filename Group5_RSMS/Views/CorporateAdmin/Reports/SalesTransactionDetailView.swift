//
//  SalesTransactionDetailView.swift
//  Group5_RSMS
//
//  Corporate Admin — Full transaction breakdown:
//  date, store, category, items, amount, estimated tax.
//

import SwiftUI

struct SalesTransactionDetailView: View {

    let transaction: SalesTransaction

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .full
        df.timeStyle = .short
        return df
    }()

    // Estimated tax at 18% GST (display only — real breakdown needs line-items table)
    private var estimatedTax: Double { transaction.totalAmount * 0.18 }
    private var preGST: Double       { transaction.totalAmount - estimatedTax }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: RSMSTheme.Spacing.lg) {
                    heroCard
                    breakdownSection
                    metaSection
                }
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, RSMSTheme.Spacing.md)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle("Transaction Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: 0) {
            // Gold accent top bar
            Rectangle()
                .fill(LinearGradient(
                    colors: [RSMSTheme.Colors.accentGold.opacity(0.8), RSMSTheme.Colors.accentGold.opacity(0.15)],
                    startPoint: .leading, endPoint: .trailing))
                .frame(height: 3)

            VStack(spacing: RSMSTheme.Spacing.md) {
                // Total amount hero
                VStack(spacing: 4) {
                    Text("TOTAL AMOUNT")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text(formatCurrency(transaction.totalAmount))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }

                Divider().background(RSMSTheme.Colors.borderLight)

                // Store + Date row
                HStack(spacing: 0) {
                    detailCell(icon: "storefront.fill",
                               label: "STORE",
                               value: transaction.storeName)
                    Divider().background(RSMSTheme.Colors.borderLight).frame(height: 36)
                    detailCell(icon: "clock.fill",
                               label: "DATE & TIME",
                               value: Self.dateFormatter.string(from: transaction.date))
                }
            }
            .padding(RSMSTheme.Spacing.lg)
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private func detailCell(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(RSMSTheme.Colors.accentGold)
            Text(label)
                .font(.system(size: 9, weight: .bold)).tracking(1)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader("Amount Breakdown")

            VStack(spacing: 0) {
                breakdownRow(label: "Subtotal (pre-GST)",
                             value: formatCurrency(preGST),
                             isBold: false)
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 14)

                breakdownRow(label: "GST @ 18% (estimated)",
                             value: formatCurrency(estimatedTax),
                             isBold: false,
                             valueColor: RSMSTheme.Colors.textSecondary)
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 14)

                breakdownRow(label: "Total Paid",
                             value: formatCurrency(transaction.totalAmount),
                             isBold: true,
                             valueColor: RSMSTheme.Colors.accentGold)
            }
            .background(RSMSTheme.Colors.backgroundDeep)
            .cornerRadius(RSMSTheme.Radius.md)
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
        }
    }

    private func breakdownRow(
        label: String,
        value: String,
        isBold: Bool,
        valueColor: Color = RSMSTheme.Colors.textPrimary
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: isBold ? .semibold : .regular))
                .foregroundStyle(isBold ? RSMSTheme.Colors.textPrimary : RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: isBold ? .bold : .medium, design: .rounded))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    // MARK: - Meta Section

    private var metaSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader("Transaction Details")

            VStack(spacing: 0) {
                metaRow(icon: "number",
                        label: "Transaction ID",
                        value: transaction.id.uuidString.uppercased())
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 14)

                metaRow(icon: "basket.fill",
                        label: "Items",
                        value: "\(transaction.itemCount) item\(transaction.itemCount == 1 ? "" : "s")")
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 14)

                metaRow(icon: "tag.fill",
                        label: "Category",
                        value: transaction.category ?? "General")
                Divider().background(Color.white.opacity(0.06)).padding(.leading, 14)

                metaRow(icon: "chart.bar.fill",
                        label: "Avg. Item Value",
                        value: transaction.itemCount > 0
                            ? formatCurrency(transaction.totalAmount / Double(transaction.itemCount))
                            : "–")
            }
            .background(RSMSTheme.Colors.backgroundDeep)
            .cornerRadius(RSMSTheme.Radius.md)
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
        }
    }

    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(RSMSTheme.Colors.accentGold)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(RSMSTheme.Colors.textSecondary)
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100000 { return "₹\(String(format: "%.2f", value/100000))L" }
        if value >= 1000   { return "₹\(String(format: "%.1f", value/1000))K" }
        return "₹\(Int(value))"
    }
}

#Preview {
    NavigationStack {
        SalesTransactionDetailView(transaction: SalesTransaction(
            id: UUID(),
            date: Date(),
            storeId: nil,
            storeName: "Mumbai Flagship",
            itemCount: 4,
            totalAmount: 12450,
            category: "Handbags"
        ))
        .environment(AppState())
    }
}
