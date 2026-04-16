//
//  ProductDetailView.swift
//  Group5_RSMS
//
//  Created by Dhiraj on 15/04/26.

//  Corporate Admin — Product Detail View. SPRINT 1 STORY 4.
//  Shows current retail price, allows setting/updating it,
//  and displays the full price_history audit trail.
//
//  The price_history audit trail must exist before POS goes live.
//  Every transaction records a unit_price at time of sale.
//

import SwiftUI

// MARK: - Price History model (maps to `price_history` Supabase table)

struct PriceHistoryEntry: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let previousPrice: Double?
    let newPrice: Double
    let changedBy: String
    let changedAt: Date
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case productId  = "product_id"
        case previousPrice = "previous_price"
        case newPrice   = "new_price"
        case changedBy  = "changed_by"
        case changedAt  = "changed_at"
        case note
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: changedAt)
    }

    var formattedNewPrice: String { formatUSD(newPrice) }
    var formattedPreviousPrice: String {
        guard let p = previousPrice else { return "—" }
        return formatUSD(p)
    }

    private func formatUSD(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - View

struct ProductDetailView: View {
    let product: Product
    var onPriceUpdated: (() -> Void)? = nil

    @State private var priceHistory: [PriceHistoryEntry] = []
    @State private var isLoadingHistory = false
    @State private var showSetPrice = false
    @State private var currentProduct: Product

    init(product: Product, onPriceUpdated: (() -> Void)? = nil) {
        self.product = product
        self.onPriceUpdated = onPriceUpdated
        _currentProduct = State(initialValue: product)
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    productInfoCard
                    priceSection
                    if !priceHistory.isEmpty {
                        priceHistorySection
                    }
                    Spacer().frame(height: RSMSTheme.Spacing.xxl)
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
            }
        }
        .navigationTitle(currentProduct.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showSetPrice, onDismiss: {
            Task { await refreshAfterPriceSet() }
        }) {
            SetPriceView(product: currentProduct)
        }
        .task {
            await fetchPriceHistory()
        }
    }

    // MARK: - Product Info Card

    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.lg) {
            HStack(spacing: RSMSTheme.Spacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Image(systemName: "tag.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                    Text(currentProduct.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text(currentProduct.sku)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
                Spacer()
            }
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Label("Official Retail Price", systemImage: "dollarsign.circle.fill")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            if currentProduct.basePrice > 0 {
                // Price is set — show current + edit button
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                        Text("CURRENT PRICE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .textCase(.uppercase)
                        Text(currentProduct.formattedPrice)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                    Spacer()
                    Button { showSetPrice = true } label: {
                        Label("Update", systemImage: "pencil")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .padding(.horizontal, RSMSTheme.Spacing.lg)
                            .padding(.vertical, RSMSTheme.Spacing.md)
                            .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(RSMSTheme.Colors.accentGold.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(RSMSTheme.Spacing.xl)
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .stroke(RSMSTheme.Colors.accentGold.opacity(0.25), lineWidth: 1)
                )

            } else {
                // No price — warning + CTA
                VStack(spacing: RSMSTheme.Spacing.lg) {
                    HStack(spacing: RSMSTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RSMSTheme.Colors.warning)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Price Set")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Text("This product cannot be sold until a retail price is set.")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    Button { showSetPrice = true } label: {
                        Label("Set Retail Price", systemImage: "dollarsign.circle")
                    }
                    .buttonStyle(GoldButtonStyle())
                }
                .padding(RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.warning.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .stroke(RSMSTheme.Colors.warning.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Price History Section

    private var priceHistorySection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Label("Price History", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            VStack(spacing: RSMSTheme.Spacing.sm) {
                ForEach(priceHistory) { entry in
                    historyRow(entry: entry)
                }
            }
        }
    }

    private func historyRow(entry: PriceHistoryEntry) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    if entry.previousPrice != nil {
                        Text(entry.formattedPreviousPrice)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .strikethrough(true, color: RSMSTheme.Colors.textSecondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    }
                    Text(entry.formattedNewPrice)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.success)
                }
                Text(entry.changedBy)
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .italic()
                }
            }

            Spacer()

            Text(entry.formattedDate)
                .font(.caption2)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                .multilineTextAlignment(.trailing)
        }
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Supabase

    @MainActor
    private func fetchPriceHistory() async {
        isLoadingHistory = true
        do {
            let entries: [PriceHistoryEntry] = try await SupabaseManager.shared.client
                .from("price_history")
                .select()
                .eq("product_id", value: currentProduct.id)
                .order("changed_at", ascending: false)
                .execute()
                .value
            self.priceHistory = entries
        } catch {
            print("❌ Failed to fetch price history: \(error)")
        }
        isLoadingHistory = false
    }

    @MainActor
    private func refreshAfterPriceSet() async {
        // Re-fetch the product to get the updated base_price
        do {
            let updated: [Product] = try await SupabaseManager.shared.client
                .from("products")
                .select()
                .eq("id", value: currentProduct.id)
                .limit(1)
                .execute()
                .value
            if let p = updated.first { currentProduct = p }
        } catch {
            print("❌ Failed to refresh product: \(error)")
        }
        await fetchPriceHistory()
        onPriceUpdated?()
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: Product(sku: "LUX-001", name: "Signature Watch", basePrice: 0))
    }
}
