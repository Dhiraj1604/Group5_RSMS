
//  Created by Dhiraj on 15/04/26.

//  SetPriceView.swift
//  Group5_RSMS
//
//  Corporate Admin — Set / Update Official Retail Price. SPRINT 1 STORY 4.
//
//  Writes to Supabase:
//    1. Updates `products.base_price`
//    2. Inserts a row into `price_history` (audit trail required before POS goes live)
//
//  Every transaction records a unit_price at time of sale.
//  Building this now ensures pricing data is clean from the very first test transaction.
//

import SwiftUI
import Supabase
import PostgREST

struct SetPriceView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let product: Product

    @State private var priceInput: String = ""
    @State private var note: String = ""
    @State private var isLoading = false
    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var errorMessage: String? = nil

    private var parsedPrice: Double? {
        let cleaned = priceInput
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(cleaned)
    }

    private var isValidPrice: Bool {
        guard let price = parsedPrice else { return false }
        return price > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        productSummary
                        priceInputSection
                        noteSection
                        auditNotice
                        confirmButton
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.lg)
                }
            }
            .navigationTitle(product.basePrice > 0 ? "Update Price" : "Set Retail Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error.")
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }

    // MARK: - Product Summary

    private var productSummary: some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "tag.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(product.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(product.sku)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
            if product.basePrice > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("CURRENT")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        .textCase(.uppercase)
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
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

    // MARK: - Price Input

    private var priceInputSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("New Retail Price (USD)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: RSMSTheme.Spacing.md) {
                Text("$")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)

                TextField("0.00", text: $priceInput)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .tint(RSMSTheme.Colors.accentGold)
                    .onChange(of: priceInput) { _, _ in
                        showValidationError = false
                    }
            }
            .padding(RSMSTheme.Spacing.xl)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(
                        showValidationError
                            ? RSMSTheme.Colors.error
                            : RSMSTheme.Colors.accentGold.opacity(0.4),
                        lineWidth: showValidationError ? 1.5 : 1
                    )
            )

            if showValidationError {
                HStack(spacing: RSMSTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(validationMessage)
                        .font(.caption)
                }
                .foregroundStyle(RSMSTheme.Colors.error)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Note

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Note (Optional)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .textCase(.uppercase)

            TextField(
                "",
                text: $note,
                prompt: Text("e.g. Global launch pricing, seasonal adjustment…")
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            )
            .font(.subheadline)
            .foregroundStyle(RSMSTheme.Colors.textPrimary)
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Audit Notice

    private var auditNotice: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "shield.checkered")
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Audit Trail")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("This change is recorded in price_history with your account, previous price, and timestamp. Every POS transaction records the unit_price at time of sale.")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.accentGold.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button { submitPrice() } label: {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isLoading ? "Saving..." : (product.basePrice > 0 ? "Update Retail Price" : "Set Retail Price"))
            }
        }
        .buttonStyle(GoldButtonStyle())
        .disabled(!isValidPrice || isLoading)
        .opacity(isValidPrice && !isLoading ? 1.0 : 0.5)
    }

    // MARK: - Submit

    private func submitPrice() {
        guard let price = parsedPrice, price > 0 else {
            withAnimation {
                showValidationError = true
                validationMessage = "Please enter a valid price greater than $0."
            }
            return
        }

        isLoading = true

        Task {
            await savePrice(newPrice: price)
        }
    }

    @MainActor
    private func savePrice(newPrice: Double) async {
        do {
            // 1. Update base_price on the product
            struct ProductPriceUpdate: Encodable {
                let base_price: Double
            }
            
            try await SupabaseManager.shared.client
                .from("products")
                .update(ProductPriceUpdate(base_price: newPrice))
                .eq("id", value: product.id)
                .execute()

            // 2. Insert price_history audit record
            struct PriceHistoryInsert: Encodable {
                let product_id: UUID
                let previous_price: Double?
                let new_price: Double
                let changed_by: String
                let note: String?
            }

            let historyRecord = PriceHistoryInsert(
                product_id: product.id,
                previous_price: product.basePrice > 0 ? product.basePrice : nil,
                new_price: newPrice,
                changed_by: appState.userEmail,
                note: note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note
            )

            try await SupabaseManager.shared.client
                .from("price_history")
                .insert(historyRecord)
                .execute()

            isLoading = false
            dismiss()

        } catch {
            print("❌ Failed to set price: \(error)")
            errorMessage = "Failed to save price: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    SetPriceView(product: Product(sku: "LUX-001", name: "Signature Watch", basePrice: 0))
        .environment(AppState())
}
