//
//  BMInventoryTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Inventory tab (Tasks 17 & 18).
//  Flow: Select boutique → View low-stock items → Initiate Transfer.
//

import SwiftUI
import Charts

struct BMInventoryTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = BMInventoryViewModel()
    @State private var animateIn = false
    @State private var selectedAlert: LowStockAlert? = nil
    @State private var hasFetchedStores = false
    @State private var selectedTabSegment = 0 // 0 = Transfer, 1 = Insights
    
    @State private var isShowingIncomingRequests = false
    @State private var isShowingMyRequests = false
    @State private var productToMove: FastMovingProduct? = nil

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
                    if viewModel.myRequests.isEmpty {
                        await viewModel.loadMyRequests(forStore: storeId)
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
            .navigationDestination(isPresented: $isShowingIncomingRequests) {
                IncomingRequestsView(currentStoreName: currentStoreName, viewModel: viewModel)
            }
            .navigationDestination(isPresented: $isShowingMyRequests) {
                MyRequestsView(currentStoreName: currentStoreName, viewModel: viewModel)
            }
            .sheet(item: $productToMove) { product in
                FloorQuantitySheet(
                    product: product,
                    storeId: appState.currentStoreID ?? UUID(),
                    viewModel: viewModel
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
                Text("Transfer").tag(0)
                Text("Merchandising Insights").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.md)
            .padding(.bottom, RSMSTheme.Spacing.sm)

            // Content
            ZStack {
                if selectedTabSegment == 0 {
                    transferSegment
                } else {
                    merchandisingSegment
                }
            }
        }
    }

    // MARK: - Merchandising Segment

    private var merchandisingSegment: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Floor Merchandising")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text("Real-time local boutique floor velocity and trends.")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, RSMSTheme.Spacing.md)

                if let error = viewModel.insightsError {
                    errorState(error)
                }
                
                fastMoversSection
                
                Spacer(minLength: 40)
            }
        }

        .task {
            if let storeId = appState.currentStoreID {
                await viewModel.loadMerchandisingInsights(forStore: storeId)
            }
        }
        .refreshable {
            if let storeId = appState.currentStoreID {
                await viewModel.loadMerchandisingInsights(forStore: storeId)
            }
        }
    }



    
    private var fastMoversSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fastest Selling Right Now")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text("Recent local sales vs the prior 3-day window")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                Spacer()
                
                let highlightedCount = viewModel.fastMovingProducts.filter { $0.trendDirection == .up }.count
                Text("\(highlightedCount) rising")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .cornerRadius(999)
            }
            
            if viewModel.fastMovingProducts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.45))
                    Text("No fast-moving products yet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text("As fresh orders come in, this section will recommend which products deserve premium floor space.")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 14) {
                    ForEach(viewModel.fastMovingProducts.prefix(5)) { product in
                        fastMoverRow(product)
                    }
                }
            }
        }
        .padding(20)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
    }



    
    private func fastMoverRow(_ product: FastMovingProduct) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Group {
                    if let urlString = product.imageUrl, let url = URL(string: urlString) {
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
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                .lineLimit(2)
                            
                            Text(product.sku)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }
                        
                        Spacer(minLength: 8)
                        trendBadge(for: product)
                    }
                    
                    Text(product.recommendationText)
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            HStack(spacing: 10) {
                metricTile(
                    title: "Recent",
                    value: "\(product.recentUnitsSold)",
                    tint: RSMSTheme.Colors.success
                )
                metricTile(
                    title: product.previousUnitsSold > 0 ? "Delta" : "Signal",
                    value: product.previousUnitsSold > 0
                        ? "\(product.velocityDelta >= 0 ? "+" : "")\(product.velocityDelta)"
                        : "New",
                    tint: product.trendDirection == .down ? RSMSTheme.Colors.error : RSMSTheme.Colors.accentGold
                )
                metricTile(
                    title: "Stock",
                    value: "\(product.currentStock)",
                    tint: product.currentStock <= 3 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.textSecondary
                )
            }
            
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(product.isOnFloor ? RSMSTheme.Colors.success : RSMSTheme.Colors.textSecondary.opacity(0.45))
                        .frame(width: 8, height: 8)
                    Text(product.isOnFloor ? "Currently on floor" : "Not on floor")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    productToMove = product
                } label: {
                    Text(product.isOnFloor ? "Remove from Floor" : "Place on Floor")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(product.isOnFloor ? RSMSTheme.Colors.textPrimary : .black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            if product.isOnFloor {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RSMSTheme.Colors.backgroundElevated)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RSMSTheme.Colors.goldGradient)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    product.isOnFloor ? RSMSTheme.Colors.borderLight : .clear,
                                    lineWidth: 1
                                )
                        )
                }
                .disabled(viewModel.isUpdatingFloorDisplay)
                .opacity(viewModel.isUpdatingFloorDisplay ? 0.65 : 1)
            }
        }
        .padding(14)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }
    
    private func trendBadge(for product: FastMovingProduct) -> some View {
        let color: Color
        let icon: String
        
        switch product.trendDirection {
        case .up:
            color = RSMSTheme.Colors.success
            icon = "arrow.up.right"
        case .steady:
            color = RSMSTheme.Colors.warning
            icon = "minus"
        case .down:
            color = RSMSTheme.Colors.error
            icon = "arrow.down.right"
        }
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(product.trendDirection.label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(999)
    }
    
    private func insightPill(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.10))
            .cornerRadius(999)
    }
    
    private func metricTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textTertiary)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
    }

    // MARK: - Transfer Segment

    private var transferSegment: some View {
        VStack(spacing: 0) {
            // Cards top section
            HStack(spacing: 16) {
                // Incoming Requests Card
                Button {
                    isShowingIncomingRequests = true
                } label: {
                    transferCard(
                        title: "Incoming Requests",
                        icon: "tray.fill",
                        hasNotification: viewModel.incomingRequests.count > 0
                    )
                }
                
                // My Requests Card
                Button {
                    isShowingMyRequests = true
                } label: {
                    transferCard(
                        title: "My Requests",
                        icon: "paperplane.fill",
                        hasNotification: false
                    )
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.sm)
            .padding(.bottom, RSMSTheme.Spacing.md)
            
            Divider()
                .background(Color.white.opacity(0.06))
            
            if viewModel.isLoading {
                loadingState
            } else if viewModel.alerts.isEmpty {
                emptyState
            } else {
                inventoryList
            }
        }
    }

    private func transferCard(title: String, icon: String, hasNotification: Bool) -> some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(RSMSTheme.Colors.goldGradient)
                }
                
                if hasNotification {
                    Circle()
                        .fill(RSMSTheme.Colors.error)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(RSMSTheme.Colors.backgroundDeep, lineWidth: 2)
                        )
                        .offset(x: 4, y: -4)
                }
            }

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 10)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
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

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(RSMSTheme.Colors.error)
            Text("Insights Unavailable")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RSMSTheme.Colors.error.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
    }
}

#Preview {
    BMInventoryTab()
        .environment(AppState())
}
