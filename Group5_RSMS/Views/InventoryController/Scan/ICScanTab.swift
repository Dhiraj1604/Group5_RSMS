//
//  ICScanTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Barcode Scan tab (Task 15).
//  Hosts the reusable BarcodeScannerView full-screen and displays
//  scanned results in a DeepSurface card with pricing breakdown.
//

import SwiftUI
import UIKit

@available(iOS 16.0, *)
struct ICScanTab: View {

    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = ICScanViewModel()
    @State private var showScanResult = false
    @State private var showManualEntry = false
    @State private var manualSKU = ""
    @FocusState private var isFieldFocused: Bool
    
    private var effectiveStoreId: UUID? {
        appState.selectedStore?.id ?? appState.currentStoreID
    }

    // MARK: - Extracted Button Labels (fixes type-check timeout)

    private var restockButtonLabel: some View {
        Image(systemName: "plus")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(Color.green.opacity(0.8))
            .clipShape(Circle())
            .shadow(color: Color.green.opacity(0.3), radius: 4)
    }

    private var saleButtonLabel: some View {
        Image(systemName: "minus")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(Color.red.opacity(0.8))
            .clipShape(Circle())
            .shadow(color: Color.red.opacity(0.3), radius: 4)
    }

    private var stockCard: some View {
        HStack {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("Current Stock in Boutique:")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer()
            if let stock = viewModel.currentStock {
                Text("\(stock)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
            }
        }
        .foregroundColor(RSMSTheme.Colors.accentGold)
        .padding(RSMSTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .stroke(RSMSTheme.Colors.accentGold.opacity(0.4), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Current stock in boutique")
        .accessibilityValue("\(viewModel.currentStock ?? 0) units")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Full-screen scanner
                BarcodeScannerView { scannedValue in
                    Task {
                        await viewModel.processSKU(scannedValue, storeId: effectiveStoreId)
                    }
                }
                .ignoresSafeArea()

                // Success Overlay (Pulse)
                if viewModel.showSuccessHUD {
                    ZStack {
                        Circle()
                            .stroke(RSMSTheme.Colors.accentGold, lineWidth: 3)
                            .scaleEffect(2.0)
                            .opacity(0)
                            .animation(.easeOut(duration: 0.6), value: viewModel.showSuccessHUD)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale.combined(with: .opacity))
                }

                // Floating HUD Notifications
                VStack {
                    if viewModel.showSuccessHUD {
                        successHUD
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if viewModel.showErrorHUD {
                        errorHUD
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .zIndex(10)

                // Bottom result card (Manually toggled or via "Details")
                if showScanResult {
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { showScanResult = false }
                            }
                        
                        resultCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .background(RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: RSMSTheme.Spacing.md) {
                        // Manual SKU Button
                        Button {
                            withAnimation(.spring()) {
                                showManualEntry = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "keyboard")
                                Text("Enter SKU")
                            }
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(RSMSTheme.Colors.backgroundElevated.opacity(0.8))
                                    .overlay(
                                        Capsule()
                                            .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.4), lineWidth: 0.5)
                                    )
                            )
                        }
                        .accessibilityLabel("Enter SKU manually")
                        .accessibilityHint("Opens manual SKU entry if scanning is not possible.")

                        if viewModel.scanCount > 0 {
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.resetSession()
                                    showScanResult = false
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(RSMSTheme.Colors.backgroundDeep.opacity(0.85))
                                            .overlay(
                                                Circle()
                                                    .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.4), lineWidth: 0.5)
                                            )
                                    )
                            }
                            .accessibilityLabel("Reset scan session")
                            .accessibilityHint("Clears scanned items and starts a new scan session.")
                        }
                    }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                manualEntrySheet
            }
            .onChange(of: viewModel.showSuccessHUD) { _, isShowing in
                guard isShowing else { return }
                let productName = viewModel.lastScannedName ?? "Product"
                UIAccessibility.post(notification: .announcement, argument: "\(productName) scanned successfully. Stock updated.")
            }
            .onChange(of: viewModel.showErrorHUD) { _, isShowing in
                guard isShowing else { return }
                UIAccessibility.post(notification: .announcement, argument: viewModel.scanError ?? "Scanning error.")
            }
        }
    }

    // MARK: - Result Card (DeepSurface)

    private var resultCard: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(RSMSTheme.Colors.accentGoldDark.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, RSMSTheme.Spacing.md)
                .padding(.bottom, RSMSTheme.Spacing.lg)

            VStack(spacing: RSMSTheme.Spacing.xl) {

                // MARK: Header: SKU and Time
                HStack(spacing: RSMSTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(RSMSTheme.Colors.backgroundElevated)
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 0.5)
                            )
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.scannedSKU ?? "—")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(RSMSTheme.Colors.accentGoldLight)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let date = viewModel.lastScanDate {
                            Text(date.formatted(date: .omitted, time: .standard))
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(RSMSTheme.Colors.accentGoldDark)
                        }
                    }

                    Spacer()

                    // Done/Save button
                    Button {
                        Task {
                            // 1. Commit any pending local adjustments to Supabase
                            let success = await viewModel.commitManualAdjustment(storeId: effectiveStoreId)
                            
                            // 2. If save succeeded (or no changes needed), close the card
                            if success {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.clearScan()
                                    showScanResult = false
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("SAVE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.Colors.goldGradient)
                        .clipShape(Capsule())
                        .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.3), radius: 4)
                    }
                    .accessibilityLabel("Save stock changes")
                    .accessibilityHint("Commits pending stock adjustments for the scanned product.")
                }

                Divider()
                    .background(RSMSTheme.Colors.accentGoldDark.opacity(0.3))

                // MARK: Receipt Body (Tax Engine Breakdown)
                if let product = viewModel.currentProduct,
                   let breakdown = viewModel.currentBreakdown,
                   let rule = viewModel.currentTaxRule {

                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                        Text(product.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                            .padding(.bottom, RSMSTheme.Spacing.xs)

                        HStack {
                            Text("Base Price")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                            Spacer()
                            Text(breakdown.subtotal.formatted(.currency(code: "INR")))
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Base Price")
                        .accessibilityValue(breakdown.subtotal.formatted(.currency(code: "INR")))

                        if breakdown.additionalTaxAmount > 0 {
                            HStack {
                                Text("Admin Tax (\(rule.name))")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Spacer()
                                Text(breakdown.additionalTaxAmount.formatted(.currency(code: "INR")))
                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Admin Tax for \(rule.name)")
                            .accessibilityValue(breakdown.additionalTaxAmount.formatted(.currency(code: "INR")))
                        }

                        Divider()
                            .background(RSMSTheme.Colors.accentGoldDark.opacity(0.3))

                        HStack {
                            Text("Total")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                            Spacer()
                            Text(breakdown.total.formatted(.currency(code: "INR")))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Total Price")
                        .accessibilityValue(breakdown.total.formatted(.currency(code: "INR")))
                    }
                    .padding(.bottom, RSMSTheme.Spacing.sm)

                    // MARK: Current Stock Status (Task 2 & 3)
                    if viewModel.currentStock != nil {
                        stockCard
                            .padding(.bottom, RSMSTheme.Spacing.md)

                        // Action Buttons
                        HStack(spacing: RSMSTheme.Spacing.xl) {
                            Spacer()
                            Button {
                                viewModel.adjustStockLocal(actionType: "restock")
                            } label: { restockButtonLabel }
                            .accessibilityLabel("Increase stock by one unit.")
                            .accessibilityValue("Current stock is \(viewModel.currentStock ?? 0) units.")
                            .accessibilityHint("Adds one unit to the scanned product stock.")

                            Button {
                                viewModel.adjustStockLocal(actionType: "sale")
                            } label: { saleButtonLabel }
                            .accessibilityLabel("Decrease stock by one unit.")
                            .accessibilityValue("Current stock is \(viewModel.currentStock ?? 0) units.")
                            .accessibilityHint("Removes one unit from the scanned product stock.")
                            Spacer()
                        }
                        .padding(.bottom, RSMSTheme.Spacing.md)
                    }

                } else if viewModel.isSearching {
                    VStack {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                            .scaleEffect(1.5)
                            .padding(.bottom, RSMSTheme.Spacing.md)
                        Text("Searching Master Catalog...")
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RSMSTheme.Spacing.xl)

                } else if let error = viewModel.scanError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(RSMSTheme.Colors.error)
                            .padding(.bottom, RSMSTheme.Spacing.sm)
                        Text(error)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.error)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RSMSTheme.Colors.error.opacity(0.1).cornerRadius(RSMSTheme.Radius.md))
                    .padding(.bottom, RSMSTheme.Spacing.md)
                }

                // MARK: Bottom Action Buttons
                VStack {
                    // Scan Again
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.clearScan()
                            showScanResult = false
                        }
                    } label: {
                        HStack(spacing: RSMSTheme.Spacing.sm) {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Scan Again")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .fill(RSMSTheme.Colors.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                        .stroke(RSMSTheme.Colors.accentGold.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityLabel("Scan again")
                    .accessibilityHint("Clears the current result and returns to the scanner.")
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.xl)
            .padding(.bottom, 28)
        }
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                        .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: -8)
        )
        .padding(.horizontal, RSMSTheme.Spacing.md)
        .padding(.bottom, RSMSTheme.Spacing.sm)
    }

    // MARK: - Manual Entry Sheet

    private var manualEntrySheet: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                        Text("Product SKU")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                        
                        TextField("e.g. JWL-RNG-001", text: Binding(
                            get: { manualSKU },
                            set: { manualSKU = $0.uppercased() }
                        ))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isFieldFocused)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                            .padding(RSMSTheme.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                    .fill(RSMSTheme.Colors.backgroundElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                            .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .accessibilityLabel("Product SKU")
                            .accessibilityHint("Enter the product SKU manually.")
                    }
                    .padding(.top, RSMSTheme.Spacing.xl)
                    
                    Button {
                        Task {
                            await viewModel.processSKU(manualSKU, storeId: effectiveStoreId)
                            showScanResult = true
                            showManualEntry = false
                            manualSKU = ""
                        }
                    } label: {
                        Text("Submit & Update Stock")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RSMSTheme.Colors.goldGradient)
                            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                    }
                    .disabled(manualSKU.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(manualSKU.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    .accessibilityLabel("Submit and update stock")
                    .accessibilityHint("Looks up the entered SKU and opens stock update details.")
                    
                    Spacer()
                }
                .padding(RSMSTheme.Spacing.xl)
            }
            .navigationTitle("Manual SKU Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showManualEntry = false
                        manualSKU = ""
                    }
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .accessibilityLabel("Cancel manual SKU entry")
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isFieldFocused = true
        }
    }

    // MARK: - Floating HUDs

    private var successHUD: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.success.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Stock Updated")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(viewModel.lastScannedName ?? "Product Verified")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    showScanResult = true
                    viewModel.showSuccessHUD = false
                }
            } label: {
                Text("DETAILS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, RSMSTheme.Spacing.lg)
        .padding(.vertical, RSMSTheme.Spacing.md)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .overlay(Capsule().stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 0.5))
                .shadow(color: Color.black.opacity(0.4), radius: 12)
        )
        .padding(.top, 10)
        .padding(.horizontal, RSMSTheme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Stock updated")
        .accessibilityValue(viewModel.lastScannedName ?? "Product verified")
    }

    private var errorHUD: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(viewModel.scanError ?? "Scanning Error")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, RSMSTheme.Spacing.lg)
        .padding(.vertical, RSMSTheme.Spacing.md)
        .background(
            Capsule()
                .fill(RSMSTheme.Colors.error.opacity(0.9))
                .shadow(color: Color.black.opacity(0.4), radius: 10)
        )
        .padding(.top, 10)
        .padding(.horizontal, RSMSTheme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scanning error")
        .accessibilityValue(viewModel.scanError ?? "Scanning Error")
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    ICScanTab()
        .preferredColorScheme(.dark)
}
