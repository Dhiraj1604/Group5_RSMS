//
//  LowStockAlertDetailView.swift
//  Group5_RSMS
//
//  Detail view for a low-stock alert.
//  Shows product image, full description, price, and stock info.
//

import SwiftUI

struct LowStockAlertDetailView: View {
    let alert: LowStockAlert

    private var quantityColor: Color {
        alert.stockQuantity <= 1
            ? RSMSTheme.Colors.error
            : RSMSTheme.Colors.warning
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: RSMSTheme.Spacing.xl) {

                    // Product Image
                    productImageSection

                    // Info Cards
                    VStack(spacing: RSMSTheme.Spacing.md) {
                        stockStatusCard
                        productInfoCard
                        storeInfoCard
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)

                    Spacer().frame(height: RSMSTheme.Spacing.xxl)
                }
            }
        }
        .navigationTitle(alert.productName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Product Image

    private var productImageSection: some View {
        Group {
            if let urlString = alert.productImageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 280)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, RSMSTheme.Colors.backgroundPrimary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 120),
                                alignment: .bottom
                            )
                    case .failure:
                        placeholderImage
                    case .empty:
                        ZStack {
                            RSMSTheme.Colors.backgroundDeep
                            ProgressView()
                                .tint(RSMSTheme.Colors.accentGold)
                        }
                        .frame(height: 280)
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        ZStack {
            RSMSTheme.Colors.backgroundDeep
            VStack(spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "photo")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
                Text("No Image Available")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Stock Status Card

    private var stockStatusCard: some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            // Quantity
            VStack(spacing: 4) {
                Text("\(alert.stockQuantity)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(quantityColor)
                Text("UNITS LEFT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(quantityColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RSMSTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .fill(quantityColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                            .stroke(quantityColor.opacity(0.2), lineWidth: 1)
                    )
            )

            // Threshold
            VStack(spacing: 4) {
                Text("\(kLowStockThreshold)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("THRESHOLD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RSMSTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                            .stroke(RSMSTheme.Colors.accentGold.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Product Info Card

    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Product Details", icon: "tag.fill")

            detailRow(label: "Name", value: alert.productName)
            detailRow(label: "SKU", value: alert.productSku, isMono: true)
            detailRow(label: "Base Price", value: String(format: "$%.2f", alert.productBasePrice))

            if let description = alert.productDescription, !description.isEmpty {
                Divider().background(RSMSTheme.Colors.borderLight)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Store Info Card

    private var storeInfoCard: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Boutique Location", icon: "storefront.fill")

            detailRow(label: "Store", value: alert.storeName)
            detailRow(label: "City", value: alert.storeCity)
        }
        .cardStyle()
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.goldGradient)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
        }
    }

    private func detailRow(label: String, value: String, isMono: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: isMono ? .monospaced : .default))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
