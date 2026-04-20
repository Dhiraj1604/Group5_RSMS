//
//  BMInventoryTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Inventory tab (Tasks 17 & 18).
//  Flow: Select boutique → View low-stock items → Initiate Transfer.
//

import SwiftUI

struct BMInventoryTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = BMInventoryViewModel()
    @State private var animateIn = false
    @State private var selectedAlert: LowStockAlert? = nil
    @State private var hasFetchedStores = false
    @State private var selectedTabSegment = 0 // 0 = Alerts, 1 = Incoming Requests

    /// Resolved current store from AppState
    private var currentStore: Store? {
        guard let storeId = appState.currentStoreID else { return nil }
        return appState.stores.first(where: { $0.id == storeId })
    }

    private var currentStoreName: String {
        currentStore?.name ?? "My Boutique"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if appState.isLoadingStores {
                    // Loading stores
                    loadingState
                } else if appState.stores.isEmpty {
                    // No stores found
                    noStoresState
                } else {
                    // Main inventory view
                    inventoryContent
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            appState.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
            .task {
                // Wait for stores to load first if needed
                if appState.stores.isEmpty {
                    await appState.loadStores()
                }
                
                // Now currentStoreID should be set
                if let storeId = appState.currentStoreID {
                    if viewModel.alerts.isEmpty {
                        await viewModel.loadAlerts(forStore: storeId)
                        withAnimation(.easeOut(duration: 0.5)) { animateIn = true }
                    }
                    if viewModel.incomingRequests.isEmpty {
                        await viewModel.loadIncomingRequests(forStore: storeId)
                    }
                }
            }
            .sheet(item: $selectedAlert) { alert in
                TransferSheet(
                    alert: alert,
                    currentStoreId: appState.currentStoreID ?? UUID(),
                    currentStoreName: currentStoreName,
                    viewModel: viewModel
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // Refresh list after transfer
                    if viewModel.transferSuccess {
                        viewModel.transferSuccess = false
                        Task {
                            if let storeId = appState.currentStoreID {
                                await viewModel.loadAlerts(forStore: storeId)
                            }
                        }
                    }
                }
            }
            .alert("Database Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }


    // MARK: - Inventory Content (after store is selected)

    private var inventoryContent: some View {
        VStack(spacing: 0) {
            // Store context header
            storeHeader
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, RSMSTheme.Spacing.sm)
                .padding(.bottom, RSMSTheme.Spacing.md)

            Divider()
                .background(Color.white.opacity(0.06))
                
            // Tab Picker
            Picker("Inventory View", selection: $selectedTabSegment) {
                Text("Low Stock Alerts").tag(0)
                Text("Incoming Requests").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.md)
            .padding(.bottom, RSMSTheme.Spacing.sm)

            // Content
            ZStack {
                if selectedTabSegment == 0 {
                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.alerts.isEmpty {
                        emptyState
                    } else {
                        inventoryList
                    }
                } else {
                    IncomingRequestsView(
                        currentStoreName: currentStoreName,
                        viewModel: viewModel
                    )
                }
            }
        }
    }

    // MARK: - Store Header

    private var storeHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(currentStoreName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text("Low Stock Items")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }

            Spacer()

            // Alert count badge
            if viewModel.alertCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(viewModel.alertCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(RSMSTheme.Colors.error)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RSMSTheme.Colors.error.opacity(0.10))
                .cornerRadius(50)
            }
        }
    }

    // MARK: - Inventory List

    private var inventoryList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(Array(viewModel.alerts.enumerated()), id: \.element.id) { index, alert in
                    inventoryItemCard(alert)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.4).delay(Double(index) * 0.07),
                            value: animateIn
                        )
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
        .refreshable {
            if let storeId = appState.currentStoreID {
                await viewModel.loadAlerts(forStore: storeId)
            }
        }
    }

    // MARK: - Inventory Item Card

    private func inventoryItemCard(_ alert: LowStockAlert) -> some View {
        let quantityColor: Color = alert.stockQuantity <= 1
            ? RSMSTheme.Colors.error
            : RSMSTheme.Colors.warning

        return VStack(spacing: 0) {
            // Top section — product info
            HStack(alignment: .top, spacing: 14) {
                // Product image / fallback
                Group {
                    if let urlString = alert.productImageUrl,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                productPlaceholder
                            @unknown default:
                                productPlaceholder
                            }
                        }
                    } else {
                        productPlaceholder
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                        .lineLimit(2)

                    Text(alert.productSku)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSTheme.Colors.accentGold)

                    Text(String(format: "$%.2f", alert.productBasePrice))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }

                Spacer()

                // Quantity
                VStack(spacing: 2) {
                    Text("\(alert.stockQuantity)")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(quantityColor)
                    Text("left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(quantityColor.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            Divider()
                .background(RSMSTheme.Colors.borderLight)
                .padding(.vertical, RSMSTheme.Spacing.md)

            // Bottom section — Transfer button
            Button {
                selectedAlert = alert
            } label: {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Initiate Transfer")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.top, RSMSTheme.Spacing.xs)
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var productPlaceholder: some View {
        ZStack {
            RSMSTheme.Colors.backgroundElevated
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(RSMSTheme.Colors.accentGoldDark.opacity(0.4))
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(RSMSTheme.Colors.accentGold)
                .scaleEffect(1.5)
            Text("Loading inventory…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - No Stores State

    private var noStoresState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.warning.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(RSMSTheme.Colors.warning)
            }
            VStack(spacing: 8) {
                Text("No Stores Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("Ask a Corporate Admin to register\nyour boutique location first.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Button {
                Task { await appState.loadStores() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Retry")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(RSMSTheme.Colors.goldGradient)
                .cornerRadius(50)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.success.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(RSMSTheme.Colors.success)
            }
            VStack(spacing: 8) {
                Text("Stock Levels Healthy")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("All products in your boutique\nare above the low-stock threshold.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

#Preview {
    BMInventoryTab()
        .environment(AppState())
}
