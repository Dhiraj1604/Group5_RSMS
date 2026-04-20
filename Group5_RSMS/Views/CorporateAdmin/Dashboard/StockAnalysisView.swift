//
//  StockAnalysisView.swift
//  Group5_RSMS
//
//  Corporate Admin — Stock Analysis per store.
//  Shows inventory levels for each SKU with low-stock / overstock flags.
//

import SwiftUI

struct StockAnalysisView: View {
    @Environment(AppState.self) private var appState
    let store: Store

    @StateObject private var viewModel = StockAnalysisViewModel()
    @State private var selectedItem: StockAnalysisViewModel.StockItem?
    @State private var showTransferSheet = false
    @State private var showReplenishAlert = false
    @State private var transferSources: [TransferSource] = []
    @State private var isLoadingSources = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.isLoading && viewModel.inventoryItems.isEmpty {
                loadingView
            } else if viewModel.inventoryItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.lg) {
                        summarySection
                        filterRow
                        stockList
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: "Search by product or SKU...")
        .refreshable { await viewModel.fetchInventory(forStore: store.id) }
        .task { await viewModel.fetchInventory(forStore: store.id) }
        .sheet(isPresented: $showTransferSheet) {
            if let item = selectedItem {
                TransferActionSheet(
                    item: item,
                    store: store,
                    sources: transferSources,
                    onComplete: {
                        Task { await viewModel.fetchInventory(forStore: store.id) }
                    }
                )
            }
        }
        .alert("Replenishment Needed", isPresented: $showReplenishAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let item = selectedItem {
                Text("\(item.productName) has only \(item.stockQuantity) unit(s) at \(store.name). Request a transfer from a store with higher stock via the Boutique Manager.")
            }
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView()
                .tint(RSMSTheme.Colors.accentGold)
                .scaleEffect(1.2)
            Text("Loading inventory...")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.3))
            Text("No Products Listed")
                .font(.title3).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .padding(.horizontal, RSMSTheme.Spacing.xxl)
    }

    // MARK: - Summary Cards
    private var summarySection: some View {
        let s = viewModel.summary
        return VStack(spacing: RSMSTheme.Spacing.sm) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                summaryCard(title: "Total SKUs", value: "\(s.total)", icon: "shippingbox.fill", color: RSMSTheme.Colors.accentGold)
                summaryCard(title: "Low Stock", value: "\(s.low)", icon: "exclamationmark.triangle.fill", color: RSMSTheme.Colors.warning)
            }
            HStack(spacing: RSMSTheme.Spacing.sm) {
                summaryCard(title: "Overstock", value: "\(s.overstock)", icon: "arrow.up.circle.fill", color: .blue)
                summaryCard(title: "Out of Stock", value: "\(s.outOfStock)", icon: "xmark.circle.fill", color: RSMSTheme.Colors.error)
            }
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(RSMSTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Filter Row
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                ForEach(StockAnalysisViewModel.StockFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(viewModel.selectedFilter == filter
                                ? .black
                                : RSMSTheme.Colors.textSecondary)
                            .background(viewModel.selectedFilter == filter
                                ? RSMSTheme.Colors.accentGold
                                : RSMSTheme.Colors.backgroundElevated)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(viewModel.selectedFilter == filter
                                        ? Color.clear
                                        : RSMSTheme.Colors.borderLight, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Stock List
    private var stockList: some View {
        LazyVStack(spacing: RSMSTheme.Spacing.sm) {
            ForEach(viewModel.filteredItems) { item in
                stockItemRow(item)
            }
        }
    }

    private func stockItemRow(_ item: StockAnalysisViewModel.StockItem) -> some View {
        let status = item.stockStatus
        let statusColor: Color = {
            switch status {
            case .outOfStock: return RSMSTheme.Colors.error
            case .low: return RSMSTheme.Colors.warning
            case .normal: return RSMSTheme.Colors.success
            case .overstock: return .blue
            }
        }()

        return HStack(spacing: RSMSTheme.Spacing.md) {
            // Quantity badge
            VStack(spacing: 2) {
                Text("\(item.stockQuantity)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }
            .frame(width: 48, height: 48)
            .background(statusColor.opacity(0.1))
            .cornerRadius(RSMSTheme.Radius.sm)

            // Product info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.productName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(item.sku) · \(item.category)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .lineLimit(1)

                // Status tag
                Text(status.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .foregroundStyle(statusColor)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
            }

            Spacer()

            // Action — only for overstock or low/out of stock
            if status == .overstock {
                Button {
                    selectedItem = item
                    Task { await loadTransferSources(for: item) }
                } label: {
                    Text("Transfer")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RSMSTheme.Colors.accentGold.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }

            if status == .low || status == .outOfStock {
                Button {
                    selectedItem = item
                    showReplenishAlert = true
                } label: {
                    Text("Replenish")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(statusColor.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(
                    status == .outOfStock ? RSMSTheme.Colors.error.opacity(0.25) :
                    status == .low ? RSMSTheme.Colors.warning.opacity(0.15) :
                    RSMSTheme.Colors.borderLight,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Load Transfer Sources
    private func loadTransferSources(for item: StockAnalysisViewModel.StockItem) async {
        isLoadingSources = true
        do {
            transferSources = try await LowStockService.shared.fetchHighStockStores(
                forProduct: item.productId,
                excluding: store.id
            )
            showTransferSheet = true
        } catch {
            print("❌ Failed to load transfer sources: \(error)")
            // If no sources found, still show the sheet with empty sources
            transferSources = []
            showTransferSheet = true
        }
        isLoadingSources = false
    }
}

// MARK: - Transfer Action Sheet

struct TransferActionSheet: View {
    let item: StockAnalysisViewModel.StockItem
    let store: Store
    let sources: [TransferSource]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity: String = "1"
    @State private var selectedSourceIndex: Int? = nil
    @State private var isTransferring = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xl) {

                        // Product header
                        HStack(spacing: RSMSTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.productName)
                                    .font(.headline).foregroundStyle(.white)
                                Text(item.sku)
                                    .font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(item.stockQuantity)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                Text("in stock")
                                    .font(.caption2)
                                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            }
                        }
                        .padding(RSMSTheme.Spacing.lg)
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(RSMSTheme.Radius.md)

                        // Destination stores
                        if sources.isEmpty {
                            VStack(spacing: RSMSTheme.Spacing.md) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 36))
                                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                Text("No stores need this product right now.")
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, RSMSTheme.Spacing.xxl)
                        } else {
                            Text("Transfer to")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)

                            ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                                Button {
                                    selectedSourceIndex = index
                                } label: {
                                    HStack(spacing: RSMSTheme.Spacing.md) {
                                        Image(systemName: selectedSourceIndex == index
                                              ? "checkmark.circle.fill"
                                              : "circle")
                                            .foregroundStyle(selectedSourceIndex == index
                                                ? RSMSTheme.Colors.accentGold
                                                : RSMSTheme.Colors.textTertiary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(source.storeName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("\(source.storeCity) · \(source.availableQuantity) units")
                                                .font(.caption)
                                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(RSMSTheme.Spacing.md)
                                    .background(selectedSourceIndex == index
                                        ? RSMSTheme.Colors.accentGold.opacity(0.08)
                                        : RSMSTheme.Colors.backgroundDeep)
                                    .cornerRadius(RSMSTheme.Radius.sm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                            .stroke(selectedSourceIndex == index
                                                ? RSMSTheme.Colors.accentGold.opacity(0.3)
                                                : RSMSTheme.Colors.borderLight, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            // Quantity
                            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                                Text("Quantity to transfer")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)

                                TextField("1", text: $quantity)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(RSMSTheme.Spacing.md)
                                    .background(RSMSTheme.Colors.backgroundDeep)
                                    .cornerRadius(RSMSTheme.Radius.sm)
                                    .foregroundStyle(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                                    )
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.Colors.error)
                            }

                            // Transfer button
                            Button {
                                Task { await executeTransfer() }
                            } label: {
                                HStack {
                                    if isTransferring {
                                        ProgressView().tint(.black)
                                    }
                                    Text(isTransferring ? "Transferring..." : "Confirm Transfer")
                                }
                            }
                            .buttonStyle(GoldButtonStyle())
                            .disabled(selectedSourceIndex == nil || isTransferring || (Int(quantity) ?? 0) < 1)
                            .opacity(selectedSourceIndex == nil ? 0.5 : 1)
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle("Transfer Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
            .alert("Transfer Complete", isPresented: $showSuccess) {
                Button("Done") {
                    onComplete()
                    dismiss()
                }
            } message: {
                Text("Stock has been transferred successfully.")
            }
        }
    }

    private func executeTransfer() async {
        guard let sourceIndex = selectedSourceIndex,
              let qty = Int(quantity), qty > 0 else {
            errorMessage = "Enter a valid quantity."
            return
        }

        let dest = sources[sourceIndex]
        isTransferring = true
        errorMessage = nil

        do {
            try await LowStockService.shared.executeTransfer(
                productId: item.productId,
                fromStoreId: store.id,
                toStoreId: dest.storeId,
                quantity: qty,
                productName: item.productName,
                fromStoreName: store.name,
                toStoreName: dest.storeName
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isTransferring = false
    }
}

// MARK: - Store Picker View

struct StockAnalysisStorePickerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if appState.stores.isEmpty {
                VStack(spacing: RSMSTheme.Spacing.lg) {
                    Image(systemName: "building.2")
                        .font(.system(size: 48))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.3))
                    Text("No Stores Available")
                        .font(.title3).fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
            } else {
                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.md) {
                        // Header
                        Text("Select a store to view stock levels and manage transfers.")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, RSMSTheme.Spacing.xs)

                        // Store List
                        ForEach(appState.stores) { store in
                            NavigationLink(destination: StockAnalysisView(store: store)) {
                                storeCard(store)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Stock Analysis")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func storeCard(_ store: Store) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(store.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("\(store.city), \(store.country)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }

            Spacer()

            Circle()
                .fill(store.isActive == true ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}
