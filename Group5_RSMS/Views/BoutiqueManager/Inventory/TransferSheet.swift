//
//  TransferSheet.swift
//  Group5_RSMS
//
//  Boutique Manager — Endless Aisle Transfer Sheet.
//  Shows available source stores with high stock and
//  allows initiating a simulated inter-store transfer.
//

import SwiftUI

struct TransferSheet: View {
    let alert: LowStockAlert
    let currentStoreId: UUID
    let currentStoreName: String
    @ObservedObject var viewModel: BMInventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSource: TransferSource? = nil
    @State private var transferQuantity: Int = 1

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RSMSTheme.Spacing.xl) {

                        // Product header
                        productHeader

                        // Source store list
                        sourceStoreSection

                        // Quantity selector (visible when a source is selected)
                        if selectedSource != nil {
                            quantitySection
                        }

                        // Transfer button
                        if selectedSource != nil {
                            transferButton
                        }

                        // Success state
                        if viewModel.transferSuccess {
                            successBanner
                        }

                        // Error state
                        if let error = viewModel.transferError {
                            errorBanner(error)
                        }

                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.lg)
                }
            }
            .navigationTitle("Request Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }
            }
            .task {
                // Reset state from any previous transfer so the
                // "Request Sent" alert doesn't fire immediately.
                viewModel.transferSuccess = false
                viewModel.transferError = nil

                await viewModel.loadTransferSources(
                    forProduct: alert.productId,
                    excluding: currentStoreId
                )
            }
            .alert("Request Sent", isPresented: Binding(
                get: { viewModel.transferSuccess },
                set: { _ in }
            )) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("\(transferQuantity) unit(s) of \(alert.productName) requested.")
            }
        }
    }

    // MARK: - Product Header

    private var productHeader: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: 14) {
                // Product icon
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .fill(RSMSTheme.Colors.error.opacity(0.10))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .stroke(RSMSTheme.Colors.error.opacity(0.25), lineWidth: 1)
                        )

                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.error)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.productName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                        .lineLimit(2)

                    Text(alert.productSku)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }

                Spacer()

                // Current stock badge
                VStack(spacing: 2) {
                    Text("\(alert.stockQuantity)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(RSMSTheme.Colors.error)
                    Text("in stock")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.error.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            // Current store context
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("Your Boutique: \(currentStoreName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Spacer()
            }
        }
        .cardStyle()
    }

    // MARK: - Source Store Section

    private var sourceStoreSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
                Text("Available Sources")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                Text("Stock > \(kHighStockThreshold)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            if viewModel.isLoadingSources {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                        Text("Finding stores with stock…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                    .padding(.vertical, RSMSTheme.Spacing.xl)
                    Spacer()
                }
            } else if viewModel.transferSources.isEmpty {
                noSourcesView
            } else {
                ForEach(viewModel.transferSources) { source in
                    sourceCard(source)
                }
            }
        }
    }

    private func sourceCard(_ source: TransferSource) -> some View {
        let isSelected = selectedSource?.storeId == source.storeId

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSource = isSelected ? nil : source
            }
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.border,
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(RSMSTheme.Colors.accentGold)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.storeName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text(source.storeCity)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }

                Spacer()

                // Available stock
                VStack(spacing: 2) {
                    Text("\(source.availableQuantity)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSTheme.Colors.success)
                    Text("available")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.success.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }
            .padding(14)
            .background(
                isSelected
                    ? RSMSTheme.Colors.accentGold.opacity(0.06)
                    : RSMSTheme.Colors.backgroundDeep
            )
            .cornerRadius(RSMSTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(
                        isSelected
                            ? RSMSTheme.Colors.accentGold.opacity(0.4)
                            : RSMSTheme.Colors.borderLight,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var noSourcesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(RSMSTheme.Colors.textTertiary)
            Text("No stores have enough stock\nfor a transfer right now.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.xl)
    }

    // MARK: - Quantity Selector

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Transfer Quantity")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: RSMSTheme.Spacing.lg) {
                // Decrease
                Button {
                    if transferQuantity > 1 { transferQuantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(
                            transferQuantity > 1
                                ? RSMSTheme.Colors.accentGold
                                : RSMSTheme.Colors.textTertiary
                        )
                }
                .disabled(transferQuantity <= 1)

                Text("\(transferQuantity)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .frame(minWidth: 50)

                // Increase
                Button {
                    let maxQty = selectedSource?.availableQuantity ?? 1
                    if transferQuantity < maxQty {
                        transferQuantity += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .cardStyle()
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Transfer Button

    private var transferButton: some View {
        Button {
            guard let source = selectedSource else { return }
            Task {
                await viewModel.requestTransfer(
                    productId: alert.productId,
                    fromSource: source,
                    toStoreId: currentStoreId,
                    quantity: transferQuantity
                )
            }
        } label: {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                if viewModel.isTransferring {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(viewModel.isTransferring ? "Requesting…" : "Request Stock")
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .buttonStyle(GoldButtonStyle())
        .disabled(viewModel.isTransferring || selectedSource == nil)
        .opacity(viewModel.isTransferring ? 0.7 : 1.0)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Request Sent")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.success)
                Text("\(transferQuantity) unit(s) of \(alert.productName) requested.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RSMSTheme.Colors.success.opacity(0.08))
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.success.opacity(0.3), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.error)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.error)
            Spacer()
        }
        .padding(14)
        .background(RSMSTheme.Colors.error.opacity(0.08))
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1)
        )
    }
}
