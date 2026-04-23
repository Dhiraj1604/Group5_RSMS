//
//  StockCheckView.swift
//  Group5_RSMS
//
//  Inventory Controller — Stock Check & Discrepancy Resolution
//
//  Flow:
//    1. Load expected counts from inventory table
//    2. Controller enters actual scanned counts per SKU
//    3. Tap "Run Check" → discrepancies surface with quantity diff
//    4. System suggests a fix with confidence rating
//    5. Controller approves → inventory updated + audit logged
//

import SwiftUI

// MARK: - Main View

struct StockCheckView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var vm = StockCheckViewModel()

    @State private var showDiscrepancies = false
    @State private var searchText = ""

    private var effectiveStoreId: UUID? {
        appState.assignedStoreId ?? appState.currentStoreID
    }

    // MARK: Filtered Items
    private var filteredItems: [StockCheckItem] {
        if searchText.isEmpty { return vm.items }
        return vm.items.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if vm.isLoading {
                    loadingView
                } else if let err = vm.errorMessage, vm.items.isEmpty {
                    errorView(err)
                } else {
                    mainContent
                }

                // Toast
                VStack {
                    Spacer()
                    if vm.showSuccessToast {
                        toastBanner
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 24)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: vm.showSuccessToast)
                .zIndex(20)
            }
            .navigationTitle("Stock Check")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
            .searchable(text: $searchText, prompt: "Search SKU or product")
            .task { await vm.load(storeId: effectiveStoreId) }
            .navigationDestination(isPresented: $showDiscrepancies) {
                DiscrepancyReportView(vm: vm)
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.xl) {
                summaryHeader
                itemsSection
                if !vm.items.isEmpty {
                    actionBar
                }
                Spacer().frame(height: RSMSTheme.Spacing.xxxl)
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.md)
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            // Check status banner
            HStack(spacing: RSMSTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(vm.checkCompletedAt != nil
                              ? RSMSTheme.Colors.success.opacity(0.15)
                              : RSMSTheme.Colors.accentGold.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: vm.checkCompletedAt != nil ? "checkmark.circle.fill" : "clipboard.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(vm.checkCompletedAt != nil
                                         ? RSMSTheme.Colors.success
                                         : RSMSTheme.Colors.accentGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.checkCompletedAt != nil ? "Check Completed" : "Stock Count in Progress")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    if let date = vm.checkCompletedAt {
                        Text("Ran \(date.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    } else {
                        Text("Enter actual counts below, then tap Run Check")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .fill(RSMSTheme.Colors.backgroundDeep)
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                            .stroke(vm.checkCompletedAt != nil
                                    ? RSMSTheme.Colors.success.opacity(0.3)
                                    : RSMSTheme.Colors.accentGoldDark.opacity(0.25),
                                    lineWidth: 1)
                    )
            )

            // KPI chips
            HStack(spacing: RSMSTheme.Spacing.sm) {
                checkChip(
                    label: "Total SKUs",
                    value: "\(vm.items.count)",
                    icon: "shippingbox.fill",
                    color: RSMSTheme.Colors.accentGold
                )
                checkChip(
                    label: "Counted",
                    value: "\(vm.items.filter { $0.scannedQty != nil }.count)",
                    icon: "checkmark.circle.fill",
                    color: RSMSTheme.Colors.success
                )
                checkChip(
                    label: "Issues",
                    value: "\(vm.discrepancies.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: vm.discrepancies.isEmpty ? RSMSTheme.Colors.textTertiary : RSMSTheme.Colors.error
                )
            }
        }
    }

    private func checkChip(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
        )
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Text("Product Inventory")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                if vm.uncountedItems > 0 {
                    Text("\(vm.uncountedItems) remaining")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.warning)
                }
            }

            if vm.items.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(filteredItems) { item in
                        StockCheckRowView(
                            item: item,
                            onQtyChanged: { qty in
                                vm.updateScanned(itemId: item.id, qty: qty)
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            // Run Check button
            Button {
                Task {
                    await vm.runStockCheck()
                    if !vm.discrepancies.isEmpty {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showDiscrepancies = true
                        }
                    }
                }
            } label: {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .bold))
                    Text(vm.checkCompletedAt == nil ? "Run Stock Check" : "Re-Run Check")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(RSMSTheme.Colors.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.35), radius: 10, y: 4)
            }
            .disabled(vm.items.filter { $0.scannedQty != nil }.isEmpty)
            .opacity(vm.items.filter { $0.scannedQty != nil }.isEmpty ? 0.4 : 1.0)

            // View Discrepancies shortcut (if already run)
            if !vm.discrepancies.isEmpty {
                Button {
                    showDiscrepancies = true
                } label: {
                    HStack(spacing: RSMSTheme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(RSMSTheme.Colors.error)
                        Text("\(vm.pendingCount) discrepancies pending review")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                    .padding(RSMSTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                            .fill(RSMSTheme.Colors.error.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                    .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Reset
            if vm.checkCompletedAt != nil {
                Button {
                    withAnimation { vm.resetCheck() }
                } label: {
                    Text("Reset Count")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if vm.isLoading {
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
            } else {
                Button {
                    Task { await vm.load(storeId: effectiveStoreId) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
    }

    // MARK: - Subsidiary Views

    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView()
                .tint(RSMSTheme.Colors.accentGold)
                .scaleEffect(1.4)
            Text("Loading inventory…")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.Colors.error)
            Text(msg)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RSMSTheme.Spacing.xl)
            Button("Retry") {
                Task { await vm.load(storeId: effectiveStoreId) }
            }
            .buttonStyle(GoldButtonStyle())
            .frame(width: 140)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "shippingbox")
                .font(.system(size: 44))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No inventory records found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.xxxl)
    }

    private var toastBanner: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(RSMSTheme.Colors.success)
            Text(vm.toastMessage ?? "")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, RSMSTheme.Spacing.xl)
        .padding(.vertical, RSMSTheme.Spacing.md)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.88))
                .overlay(Capsule().stroke(RSMSTheme.Colors.success.opacity(0.4), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.4), radius: 12)
        )
        .padding(.horizontal, RSMSTheme.Spacing.xl)
    }
}

// MARK: - Row View

struct StockCheckRowView: View {
    let item: StockCheckItem
    let onQtyChanged: (Int) -> Void

    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    private var parsedQty: Int? { Int(inputText) }

    private var rowStatus: RowStatus {
        guard let qty = parsedQty else { return .uncounted }
        if qty == item.expectedQty { return .match }
        return qty < item.expectedQty ? .shortage : .surplus
    }

    private enum RowStatus {
        case uncounted, match, shortage, surplus
        var color: Color {
            switch self {
            case .uncounted: return RSMSTheme.Colors.borderLight
            case .match:     return RSMSTheme.Colors.success
            case .shortage:  return RSMSTheme.Colors.error
            case .surplus:   return RSMSTheme.Colors.warning
            }
        }
        var icon: String? {
            switch self {
            case .uncounted: return nil
            case .match:     return "checkmark.circle.fill"
            case .shortage:  return "arrow.down.circle.fill"
            case .surplus:   return "arrow.up.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {

            // Status indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(rowStatus.color)
                .frame(width: 4)
                .frame(height: 56)
                .animation(.easeInOut(duration: 0.2), value: rowStatus.color)

            // Product info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.productName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("SKU: \(item.sku)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }

            Spacer()

            // Expected qty label
            VStack(alignment: .trailing, spacing: 2) {
                Text("Expected")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                Text("\(item.expectedQty)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            // Arrow separator
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)

            // Actual count field
            VStack(alignment: .trailing, spacing: 2) {
                Text("Actual")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)

                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                        .fill(RSMSTheme.Colors.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                .stroke(
                                    isFocused ? RSMSTheme.Colors.accentGold : rowStatus.color,
                                    lineWidth: isFocused ? 1.5 : 1
                                )
                        )
                        .frame(width: 58, height: 32)
                        .animation(.easeInOut(duration: 0.15), value: isFocused)

                    TextField("—", text: $inputText)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .frame(width: 52)
                        .onChange(of: inputText) { _, new in
                            if let qty = Int(new) {
                                onQtyChanged(qty)
                            }
                        }
                }
            }

            // Status icon
            if let icon = rowStatus.icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(rowStatus.color)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rowStatus.icon)
            } else {
                Color.clear.frame(width: 16)
            }
        }
        .padding(.horizontal, RSMSTheme.Spacing.lg)
        .padding(.vertical, RSMSTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .stroke(rowStatus.color.opacity(parsedQty != nil ? 0.3 : 0.1), lineWidth: 1)
                )
        )
        .onAppear {
            if let qty = item.scannedQty {
                inputText = "\(qty)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StockCheckView()
        .environment(AppState())
}
