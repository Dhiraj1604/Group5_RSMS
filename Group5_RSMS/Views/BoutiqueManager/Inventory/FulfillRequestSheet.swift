//
//  FulfillRequestSheet.swift
//  Group5_RSMS
//
//  Boutique Manager — Fulfill an Incoming Request Sheet.
//  Implements Rule A (max constraint) & Rule B (partial fulfillment).
//

import SwiftUI

struct FulfillRequestSheet: View {
    let request: TransferRequest
    let currentStoreName: String
    @ObservedObject var viewModel: BMInventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var transferQuantity: Int = 1
    @State private var availableStock: Int = 0
    @State private var isCheckingStock: Bool = true
    @State private var fetchError: String? = nil

    private var isPartialFulfillment: Bool {
        transferQuantity < request.quantity
    }
    
    private var exceedsStock: Bool {
        transferQuantity > availableStock
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Request Header
                        requestHeader

                        // Form Content
                        if isCheckingStock {
                            fetchingStockIndicator
                        } else if let error = fetchError {
                            errorBanner(error)
                        } else {
                            quantitySection
                            
                            if !exceedsStock && isPartialFulfillment {
                                partialFulfillmentWarning
                            }
                            
                            fulfillButton
                        }

                        // Success state
                        if viewModel.transferSuccess {
                            successBanner
                        }

                        // Submit error state
                        if let error = viewModel.transferError {
                            errorBanner(error)
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Fulfill Request")
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
                transferQuantity = request.quantity
                await loadAvailableStock()
            }
        }
    }

    private func loadAvailableStock() async {
        isCheckingStock = true
        fetchError = nil
        do {
            self.availableStock = try await LowStockService.shared.fetchCurrentStock(productId: request.productId, storeId: request.fulfillingStoreId)
        } catch {
            self.fetchError = "Could not verify your inventory: \(error.localizedDescription)"
        }
        isCheckingStock = false
    }

    // MARK: - Header

    private var requestHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Product icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.10))
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                        )

                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.productName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.primary)
                        .lineLimit(2)

                    Text(request.productSku)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.accentColor)
                }

                Spacer()

                // Requested qty badge
                VStack(spacing: 2) {
                    Text("\(request.quantity)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Color.primary)
                    Text("Requested")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.secondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            Divider()
                .background(Color(UIColor.separator).opacity(0.5))
            
            // To Store Context
            HStack(spacing: 6) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
                Text("Requested By: \(request.requestingStoreName) (\(request.requestingStoreCity))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.primary)
                Spacer()
            }
            // Date Context
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color.secondary)
                Text("Sent: \(request.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.secondary)
                Spacer()
            }
        }
        .cardStyle()
    }

    // MARK: - Quantity Selector

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fulfill Quantity")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.primary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                
                Spacer()
                
                Text("\(availableStock) available")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(availableStock > 0 ? Color.green : Color.red)
            }

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
                    .foregroundColor(exceedsStock ? Color.red : Color.primary)
                    .frame(minWidth: 50)

                // Increase
                // Rule A: Limit mathematically bound if wanted, but UI feedback requires we show them exceeding and disabling. We'll disable it only if it goes absolutely crazy.
                // It's usually better UX to block stepping over available stock.
                Button {
                    transferQuantity += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity)
            
            if exceedsStock {
                Text("You cannot fulfill more than you have in stock (\(availableStock)).")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .cardStyle()
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var partialFulfillmentWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Partial Fulfillment")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.primary)
                Text("You are fulfilling \(transferQuantity) out of the requested \(request.quantity) units. This will mark the request as fulfilled.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.secondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var fetchingStockIndicator: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.accentColor)
            Text("Checking your stock…")
                .font(.system(size: 13))
                .foregroundColor(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Transfer Button

    private var fulfillButton: some View {
        Button {
            Task {
                await viewModel.fulfillRequest(
                    request,
                    fulfilledQuantity: transferQuantity,
                    currentStoreName: currentStoreName
                )
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isTransferring {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(viewModel.isTransferring ? "Fulfilling…" : (isPartialFulfillment ? "Fulfill Partially" : "Fulfill Request"))
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .buttonStyle(GoldButtonStyle())
        // Rule A strict enforcement: disabled if exceeds stock
        .disabled(viewModel.isTransferring || exceedsStock || transferQuantity <= 0)
        .opacity((viewModel.isTransferring || exceedsStock || transferQuantity <= 0) ? 0.5 : 1.0)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Request Fulfilled")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.green)
                Text("\(transferQuantity) unit(s) transferred successfully.")
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
