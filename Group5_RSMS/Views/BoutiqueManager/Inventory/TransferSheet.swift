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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

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

                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Request Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.secondary)
                    }
                }
            }
            .task {
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
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Product icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.10))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.25), lineWidth: 1)
                        )

                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.productName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.primary)
                        .lineLimit(2)

                    Text(alert.productSku)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.accentColor)
                }

                Spacer()

                // Current stock badge
                VStack(spacing: 2) {
                    Text("\(alert.stockQuantity)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Color.red)
                    Text("in stock")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.red.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            // Current store context
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.accentColor)
                Text("Your Boutique: \(currentStoreName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.secondary)
                Spacer()
            }
        }
        .cardStyle()
    }

    // MARK: - Source Store Section

    private var sourceStoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor.gradient)
                Text("Available Sources")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.primary)
                Spacer()
                Text("Stock > \(kHighStockThreshold)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            if viewModel.isLoadingSources {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(Color.accentColor)
                        Text("Finding stores with stock…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.secondary)
                    }
                    .padding(.vertical, 24)
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
                            isSelected ? Color.accentColor : Color(UIColor.separator),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.storeName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.primary)
                    Text(source.storeCity)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.secondary)
                }

                Spacer()

                // Available stock
                VStack(spacing: 2) {
                    Text("\(source.availableQuantity)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color.green)
                    Text("available")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Color.green.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }
            .padding(14)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.06)
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(0.4)
                            : Color(UIColor.separator).opacity(0.5),
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
                .foregroundColor(Color.secondary)
            Text("No stores have enough stock\nfor a transfer right now.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Quantity Selector

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transfer Quantity")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.primary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 16) {
                // Decrease
                Button {
                    if transferQuantity > 1 { transferQuantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(
                            transferQuantity > 1
                                ? Color.accentColor
                                : Color.secondary
                        )
                }
                .disabled(transferQuantity <= 1)

                Text("\(transferQuantity)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary)
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
                        .foregroundColor(Color.accentColor)
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
            HStack(spacing: 8) {
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
                .foregroundColor(Color.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Request Sent")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.green)
                Text("\(transferQuantity) unit(s) of \(alert.productName) requested.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.red)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.red)
            Spacer()
        }
        .padding(14)
        .background(Color.red.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}
