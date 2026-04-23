//
//  ICShipmentsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Shipments Tab.
//  Displays customer orders pending shipment and shipped ones.
//

import SwiftUI

enum ShipmentTab: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case shipped = "Shipped"
    
    var id: String { self.rawValue }
}

struct ICShipmentsTab: View {
    @Environment(AppState.self) private var appState
    @State private var orders: [CustomerOrder] = []
    @State private var isLoading = false
    @State private var fetchError: String? = nil
    @State private var selectedTab: ShipmentTab = .pending
    @State private var selectedOrderForDetails: CustomerOrder?
    @Namespace private var animation
    
    @State private var fromDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var toDate: Date = Date()
    @State private var isFilterApplied: Bool = false
    @State private var showFilterSheet: Bool = false

    private let shipmentService = CustomerShipmentService()

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segmented Control
                    segmentedControl
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.top, RSMSTheme.Spacing.sm)
                        .padding(.bottom, RSMSTheme.Spacing.md)

                    if isLoading {
                        Spacer()
                        loadingState
                        Spacer()
                    } else if let error = fetchError {
                        Spacer()
                        errorState(error)
                        Spacer()
                    } else if orders.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ordersList
                    }
                }
            }
            .navigationTitle("Shipments")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: isFilterApplied ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(isFilterApplied ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textPrimary)
                    }
                }
            }
            .task {
                await loadOrders()
            }
            .onChange(of: selectedTab) { _ in
                Task { await loadOrders() }
            }
            .refreshable {
                await loadOrders()
            }
            .sheet(item: $selectedOrderForDetails) { order in
                OrderDetailsSheet(order: order)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showFilterSheet) {
                NavigationStack {
                    filterSheetContent
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ShipmentTab.allCases) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(RSMSTheme.Colors.accentGold)
                                        .matchedGeometryEffect(id: "TAB_BG", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }

    private var filterSheetContent: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    DatePicker("From Date", selection: $fromDate, displayedComponents: .date)
                        .colorScheme(.dark)
                        .tint(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(12)
                    
                    DatePicker("To Date", selection: $toDate, displayedComponents: .date)
                        .colorScheme(.dark)
                        .tint(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Clear") {
                        isFilterApplied = false
                        fromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        toDate = Date()
                        showFilterSheet = false
                        Task { await loadOrders() }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.Colors.border.opacity(0.3))
                    .cornerRadius(12)
                    
                    Button("Apply") {
                        isFilterApplied = true
                        showFilterSheet = false
                        Task { await loadOrders() }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.Colors.accentGold)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Filter Shipments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    showFilterSheet = false
                }
                .foregroundColor(RSMSTheme.Colors.accentGold)
                .fontWeight(.semibold)
            }
        }
    }

    private func loadOrders() async {
            isLoading = true
            fetchError = nil
            do {
                let fDate = isFilterApplied ? Calendar.current.startOfDay(for: fromDate) : nil
                let tDate = isFilterApplied ? Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: toDate) : nil
                
                self.orders = try await shipmentService.fetchShipments(for: selectedTab, storeId: appState.currentStoreID, fromDate: fDate, toDate: tDate)
            } catch {
                self.fetchError = error.localizedDescription
            }
            isLoading = false
        }

    private var ordersList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(orders) { order in
                    orderCard(for: order)
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.bottom, 40)
        }
    }

    private func orderCard(for order: CustomerOrder) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.orderNumber.prefix(8).uppercased())")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    
                    Text("\(order.consolidatedItems.count) items • \(order.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                // Status badge
                Text(order.status.capitalized)
                    .font(.system(size: 11, weight: .bold))
                    // 1. Force the text to be gold
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    // 2. Force the background to be the 15% opacity gold
                    .background(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .cornerRadius(6)
            }
            
            // Product Images Scroll
            let items = order.consolidatedItems
            if !items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(items) { item in
                            VStack(spacing: 4) {
                                // Image
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(RSMSTheme.Colors.border.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                    
                                    if let urlString = item.product?.imageUrl ?? item.productImageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } placeholder: {
                                            Image(systemName: "photo")
                                                .foregroundColor(RSMSTheme.Colors.textTertiary)
                                        }
                                    } else {
                                        Image(systemName: "shippingbox.fill")
                                            .foregroundColor(RSMSTheme.Colors.textTertiary)
                                            .font(.system(size: 24))
                                    }
                                    
                                    // Quantity badge
                                    if item.quantity > 1 {
                                        Text("x\(item.quantity)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(RSMSTheme.Colors.accentGold)
                                            .clipShape(Capsule())
                                            .offset(x: 20, y: -20)
                                    }
                                }
                                
                                let displayName = item.product?.name ?? item.productName
                                Text(displayName.isEmpty ? "Unknown Product" : displayName)
                                    .font(.system(size: 10))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                            .onTapGesture {
                                selectedOrderForDetails = order
                            }
                        }
                    }
                }
            }
            
            Divider()
                .background(RSMSTheme.Colors.borderLight)
            
            // Action button
            if selectedTab == .pending {
                Button {
                    updateStatus(for: order, to: "shipped")
                } label: {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                        Text("Mark as Shipped")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.Colors.accentGold)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            } else {
                Button {
                    updateStatus(for: order, to: "placed")
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Move to Pending")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.Colors.border.opacity(0.5))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    private func updateStatus(for order: CustomerOrder, to newStatus: String) {
        Task {
            do {
                try await shipmentService.updateOrderStatus(orderId: order.id, newStatus: newStatus)
                // Remove from current list visually
                withAnimation {
                    orders.removeAll { $0.id == order.id }
                }
            } catch {
                print("Failed to update order status: \(error.localizedDescription)")
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(RSMSTheme.Colors.accentGold)
                .scaleEffect(1.5)
            Text("Loading shipments data...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
        }
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(RSMSTheme.Colors.error)
            Text("Error loading shipments")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(msg)
                .font(.system(size: 14))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadOrders() }
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.top, 8)
        }
        .padding(32)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.border.opacity(0.3))
                    .frame(width: 88, height: 88)
                Image(systemName: selectedTab == .pending ? "shippingbox.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
            VStack(spacing: 8) {
                Text(selectedTab == .pending ? "No Pending Shipments" : "No Shipped Orders")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(selectedTab == .pending ? "All customer orders have been shipped." : "You haven't shipped any orders yet.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Details Sheet
struct OrderDetailsSheet: View {
    let order: CustomerOrder
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Order #\(order.orderNumber.uppercased())")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(order.status.capitalized) • \(order.createdAt.formatted(date: .long, time: .shortened))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                Divider()
                    .background(RSMSTheme.Colors.borderLight)
                
                // Products List
                ScrollView {
                    VStack(spacing: 16) {
                        let items = order.consolidatedItems
                        if !items.isEmpty {
                            ForEach(items) { item in
                                productRow(for: item)
                            }
                        } else {
                            Text("No items found for this order.")
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    private func productRow(for item: CustomerOrderItem) -> some View {
        HStack(spacing: 16) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.Colors.border.opacity(0.3))
                    .frame(width: 70, height: 70)
                
                if let urlString = item.product?.imageUrl ?? item.productImageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                        .font(.system(size: 30))
                }
            }
            
            // Product Details
            VStack(alignment: .leading, spacing: 6) {
                let displayName = item.product?.name ?? item.productName
                Text(displayName.isEmpty ? "Unknown Product" : displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let variant = item.variant, !variant.isEmpty {
                    Text("Variant: \(variant)")
                        .font(.system(size: 13))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                
                HStack {
                    Text("Qty: \(item.quantity)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }
}
