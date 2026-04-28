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

    // Resolved current store from AppState

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
            // Tab Picker
            Picker("Inventory View", selection: $selectedTabSegment) {
                Text("Transfer").tag(0)
                Text("Merchandising Insights").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.vertical, RSMSTheme.Spacing.md)

            // Content
            if selectedTabSegment == 0 {
                transferList
            } else {
                ScrollView(showsIndicators: false) {
                    merchandisingSegment
                }
            }
        }
    }

    // MARK: - Merchandising Segment

    private var merchandisingSegment: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Merchandising")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text("Optimize your floor space based on real-time sales velocity.")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.lg)


            if let error = viewModel.insightsError {
                errorState(error)
            }
            
            fastMoversSection
            
            Spacer(minLength: 40)
        }
        .task {
            if let storeId = appState.currentStoreID {
                await viewModel.loadMerchandisingInsights(forStore: storeId)
            }
        }
    }



    
    private var fastMoversSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Performers")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text("Fastest moving items in this boutique")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                Spacer()
                
                let risingCount = viewModel.fastMovingProducts.filter { $0.trendDirection == .up }.count
                if risingCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                        Text("\(risingCount) RISING")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .cornerRadius(8)
                }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                // Product image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        productPlaceholder
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))

                
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(product.sku)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                    
                    compactMetricsRow(for: product)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                trendBadge(for: product)
            }
            
            Divider()
                .background(RSMSTheme.Colors.borderLight.opacity(0.5))
            
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(product.isOnFloor ? RSMSTheme.Colors.success : RSMSTheme.Colors.textSecondary.opacity(0.45))
                        .frame(width: 6, height: 6)
                    Text(product.isOnFloor ? "On Floor" : "Backstock")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    productToMove = product
                } label: {
                    Text(product.isOnFloor ? "Remove" : "Place on Floor")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(product.isOnFloor ? RSMSTheme.Colors.textPrimary : .black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background {
                            if product.isOnFloor {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(RSMSTheme.Colors.backgroundElevated)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(RSMSTheme.Colors.goldGradient)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
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
        .padding(12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    private func compactMetricsRow(for product: FastMovingProduct) -> some View {
        HStack(spacing: 12) {
            metricItem(icon: "flame.fill", value: "\(product.recentUnitsSold)", color: RSMSTheme.Colors.error)
            
            let delta = product.velocityDelta
            metricItem(
                icon: delta >= 0 ? "arrow.up.right" : "arrow.down.right",
                value: delta > 0 ? "+\(delta)" : "\(delta)",
                color: delta >= 0 ? RSMSTheme.Colors.success : RSMSTheme.Colors.error
            )
            
            metricItem(icon: "box.truck.fill", value: "\(product.currentStock)", color: RSMSTheme.Colors.accentGold)
        }
    }

    private func metricItem(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
        }
    }

    
    private func trendBadge(for product: FastMovingProduct) -> some View {
        let color: Color
        let icon: String
        let label: String
        
        switch product.trendDirection {
        case .up:
            color = RSMSTheme.Colors.success
            icon = "arrow.up.right"
            label = "High"
        case .steady:
            color = RSMSTheme.Colors.warning
            icon = "minus"
            label = "Stable"
        case .down:
            color = RSMSTheme.Colors.error
            icon = "arrow.down.right"
            label = "Low"
        }
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(label.uppercased())
                .font(.system(size: 9, weight: .black))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(6)
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
    
    // Removed metricTile as it's replaced by compactMetricsRow


    // MARK: - Transfer Segment (Refactored to List for native Swipe Actions)

    private var transferList: some View {
        List {
            // 1. Store Header (Exclusive to Transfer)
            Section {
                storeHeader
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // 2. Management Header & Cards
            Section {
                Text("Management")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                HStack(spacing: 16) {
                    Button { isShowingIncomingRequests = true } label: {
                        transferCard(title: "Incoming Requests", icon: "tray.fill",
                                     hasNotification: viewModel.incomingRequests.count > 0)
                    }
                    Button { isShowingMyRequests = true } label: {
                        transferCard(title: "My Requests", icon: "paperplane.fill",
                                     hasNotification: false)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // 3. Low Stock Alerts Section
            Section {
                Text("Stock Alerts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .padding(.bottom, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(RSMSTheme.Colors.accentGold)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if viewModel.alerts.isEmpty {
                    emptyState
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.alerts) { alert in
                        inventoryItemCard(alert)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    selectedAlert = alert
                                } label: {
                                    Label("Transfer", systemImage: "arrow.triangle.swap")
                                }
                                .tint(RSMSTheme.Colors.accentGold)
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            if let storeId = appState.currentStoreID {
                await viewModel.loadAlerts(forStore: storeId)
            }
        }
    }

    private func transferCard(title: String, icon: String, hasNotification: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(RSMSTheme.Colors.goldGradient)
                }
                
                if hasNotification {
                    Circle()
                        .fill(RSMSTheme.Colors.error)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(RSMSTheme.Colors.backgroundElevated, lineWidth: 1.5))
                }
            }
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Store Header

    private var storeHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "storefront.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(RSMSTheme.Colors.goldGradient)

            Text(currentStoreName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Alert count badges
            HStack(spacing: 8) {
                if viewModel.criticalAlertsCount > 0 {
                    alertBadge(count: viewModel.criticalAlertsCount, color: RSMSTheme.Colors.error)
                }
                if viewModel.warningAlertsCount > 0 {
                    alertBadge(count: viewModel.warningAlertsCount, color: RSMSTheme.Colors.warning)
                }
            }
        }
    }

    private func alertBadge(count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .bold))
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.10))
        .cornerRadius(50)
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
        let quantityColor: Color = alert.stockQuantity <= 2
            ? RSMSTheme.Colors.error
            : RSMSTheme.Colors.warning

        return HStack(alignment: .top, spacing: 14) {
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
