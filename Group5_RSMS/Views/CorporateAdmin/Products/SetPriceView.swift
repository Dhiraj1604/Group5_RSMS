//
//  SetPriceView.swift
//  Group5_RSMS
//
//  Created by Dhiraj on 15/04/26.
//

import SwiftUI
import Supabase
import PostgREST
import Foundation

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
            .replacingOccurrences(of: "₹", with: "")
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
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.lg)
                }
            }
            .navigationTitle(product.basePrice > 0 ? "Update Price" : "Set Retail Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { submitPrice() } label: {
                        if isLoading {
                            ProgressView().tint(RSMSTheme.Colors.accentGold)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .disabled(!isValidPrice || isLoading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { submitPrice() }) {
                        if isLoading {
                            ProgressView().tint(RSMSTheme.Colors.accentGold)
                        } else {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundStyle(isValidPrice ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textTertiary)
                    .disabled(!isValidPrice || isLoading)
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
            Text("New Retail Price (INR)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: RSMSTheme.Spacing.md) {
                Text("₹")
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
                Text("This change will be recorded")
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

    // MARK: - Submit Logic

    private func submitPrice() {
        guard let price = parsedPrice, price > 0 else {
            withAnimation {
                showValidationError = true
                validationMessage = "Please enter a valid price greater than ₹0."
            }
            return
        }

        Task {
            await savePrice(newPrice: price)
        }
    }

    @MainActor
    private func savePrice(newPrice: Double) async {
        // Nested struct for DTO
        struct PriceHistoryInsert: Encodable {
            let product_id: UUID
            let previous_price: Double?
            let new_price: Double
            let changed_by: String
            let note: String?
        }

        isLoading = true
        errorMessage = nil

        // 1. Update the products table — this is the critical operation
        do {
            try await SupabaseManager.shared.client
                .from("products")
                .update(["base_price": newPrice])
                .eq("id", value: product.id)
                .execute()
        } catch {
            print("❌ Price update failed: \(error)")
            errorMessage = "Error: \(error.localizedDescription)"
            isLoading = false
            return
        }

        // 2. Insert Audit History Row (best-effort; don't block the user if this fails)
        do {
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
        } catch {
            // Audit trail failed but price IS updated — log and continue
            print("⚠️ Price updated but audit history insert failed: \(error)")
        }

        // 3. Update AppState directly for immediate UI reaction
        if let index = appState.products.firstIndex(where: { $0.id == product.id }) {
            appState.products[index].basePrice = newPrice
        }

        // 4. Log to audit trail
        ActivityLogService.shared.log(
            userEmail: appState.userEmail,
            action: .updated,
            entity: .product,
            entityName: product.name,
            entityId: product.id.uuidString,
            details: "Price updated",
            before: ["base_price": String(format: "%.2f", product.basePrice)],
            after: ["base_price": String(format: "%.2f", newPrice)]
        )

        // 5. Background sync to pick up updated_at and any server-side changes
        await appState.fetchProducts()

        isLoading = false
        dismiss()
    }
}

#Preview {
    SetPriceView(product: Product.sample)
        .environment(AppState())
}
