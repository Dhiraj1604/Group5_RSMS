//
//  ICScanTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Barcode Scan tab (Task 15).
//  Hosts the reusable BarcodeScannerView full-screen and displays
//  scanned results in a DeepSurface card with pricing breakdown.
//

import SwiftUI

@available(iOS 16.0, *)
struct ICScanTab: View {

    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = ICScanViewModel()
    @State private var showScanResult = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Full-screen scanner
                BarcodeScannerView { scannedValue in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        viewModel.didScanBarcode(scannedValue, storeId: appState.currentStoreID)
                        showScanResult = true
                    }
                }
                .ignoresSafeArea()

                // Bottom result card
                if showScanResult, viewModel.scannedSKU != nil {
                    resultCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                    }
                }
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

            // SKU display
            VStack(spacing: RSMSTheme.Spacing.xl) {
                // Header: SKU and Time
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

                    // Copy button
                    Button {
                        if let sku = viewModel.scannedSKU {
                            UIPasteboard.general.string = sku
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .padding(RSMSTheme.Spacing.sm)
                            .background(
                                Circle()
                                    .fill(RSMSTheme.Colors.backgroundElevated)
                                    .overlay(
                                        Circle()
                                            .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }
                }

                Divider()
                    .background(RSMSTheme.Colors.accentGoldDark.opacity(0.3))

                // Receipt Body (Tax Engine Breakdown)
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
                            Text(String(format: "$%.2f", breakdown.subtotal))
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }

                        HStack {
                            Text("Tax (\(rule.name))")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                            Spacer()
                            Text(String(format: "$%.2f", breakdown.taxAmount))
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }

                        Divider()
                            .background(RSMSTheme.Colors.accentGoldDark.opacity(0.3))

                        HStack {
                            Text("Total")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                            Spacer()
                            Text(String(format: "$%.2f", breakdown.total))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }
                    }
                    .padding(.bottom, RSMSTheme.Spacing.sm)
                    
                    // Current Stock Status (Task 2 & 3)
                    if let stock = viewModel.currentStock {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Current Stock in Boutique:")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            Spacer()
                            Text("\(stock)")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
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
                        .padding(.bottom, RSMSTheme.Spacing.md)
                        
                        // Action Buttons (Task 3)
                        HStack(spacing: RSMSTheme.Spacing.md) {
                            Button {
                                Task {
                                    await viewModel.logInventoryAction(actionType: "restock", storeId: appState.currentStoreID)
                                }
                            } label: {
                                HStack(spacing: RSMSTheme.Spacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("RESTOCK")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green.opacity(0.8).cornerRadius(RSMSTheme.Radius.sm))
                            }
                            
                            Button {
                                Task {
                                    await viewModel.logInventoryAction(actionType: "sale", storeId: appState.currentStoreID)
                                }
                            } label: {
                                HStack(spacing: RSMSTheme.Spacing.sm) {
                                    Image(systemName: "minus.circle.fill")
                                    Text("SALE")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.8).cornerRadius(RSMSTheme.Radius.sm))
                            }
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

                // Action buttons
                HStack(spacing: RSMSTheme.Spacing.md) {
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
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .fill(RSMSTheme.Colors.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                        .stroke(RSMSTheme.Colors.accentGold.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }

                    // Lookup (Trigger Inventory Refresh)
                    Button {
                        if let sku = viewModel.scannedSKU {
                            Task {
                                await viewModel.didScanBarcode(sku, storeId: appState.currentStoreID)
                            }
                        }
                    } label: {
                        HStack(spacing: RSMSTheme.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Lookup")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(RSMSTheme.Colors.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .fill(RSMSTheme.Colors.goldGradient)
                        )
                    }
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
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    ICScanTab()
        .preferredColorScheme(.dark)
}
