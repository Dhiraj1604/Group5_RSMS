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
    
    @State private var storeInventory: [UUID: Int] = [:]
    @State private var showNotifyAlert: Bool = false
    @State private var notifyMessage: String = ""
    @State private var notifiedOrders: Set<UUID> = []

    private let shipmentService = CustomerShipmentService()
    private let reportService = ICReportsService()

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Native Segmented Picker (Scrolling along with content)
                        Picker("Shipment View", selection: $selectedTab) {
                            ForEach(ShipmentTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.top, RSMSTheme.Spacing.md)
                        .padding(.bottom, RSMSTheme.Spacing.md)

                        if isLoading && orders.isEmpty {
                            VStack {
                                Spacer(minLength: 100)
                                loadingState
                                Spacer()
                            }
                        } else if let error = fetchError {
                            VStack {
                                Spacer(minLength: 100)
                                errorState(error)
                                Spacer()
                            }
                        } else if orders.isEmpty {
                            VStack {
                                Spacer(minLength: 100)
                                emptyState
                                Spacer()
                            }
                        } else {
                            // Orders List
                            LazyVStack(spacing: 16) {
                                ForEach(orders) { order in
                                    orderCard(for: order)
                                }
                            }
                            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .refreshable {
                    await loadOrders()
                }
            }
            .navigationTitle("Shipments")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
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
            .onChange(of: selectedTab) {
                Task { await loadOrders() }
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
            .alert("Notification Sent", isPresented: $showNotifyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(notifyMessage)
            }
        }
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
                
                async let fetchOrders = shipmentService.fetchShipments(for: selectedTab, storeId: appState.currentStoreID, fromDate: fDate, toDate: tDate)
                async let fetchInventory = reportService.fetchInventoryHeatMapData(storeId: appState.currentStoreID)
                
                let (fetchedOrders, fetchedInventory) = try await (fetchOrders, fetchInventory)
                
                self.orders = fetchedOrders
                
                var inventoryMap: [UUID: Int] = [:]
                for item in fetchedInventory {
                    inventoryMap[item.productId] = item.stockQuantity
                }
                self.storeInventory = inventoryMap
                
            } catch {
                if !(error is CancellationError) {
                    self.fetchError = error.localizedDescription
                }
            }
            isLoading = false
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
                                    
                                    if let url = resolvePublicImageUrl(for: item.product?.imageUrl ?? item.productImageUrl) {
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
                let canBeShipped = items.allSatisfy { item in
                    let stock = storeInventory[item.productId] ?? 0
                    return stock >= item.quantity
                }
                
                if canBeShipped {
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
                    let isNotified = notifiedOrders.contains(order.id)
                    Button {
                        if !isNotified {
                            notifyManager(for: order)
                        }
                    } label: {
                        HStack {
                            Image(systemName: isNotified ? "bell.badge.fill" : "bell.fill")
                            Text(isNotified ? "Manager Notified" : "Notify Manager")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isNotified ? RSMSTheme.Colors.border.opacity(0.5) : RSMSTheme.Colors.error.opacity(0.8))
                        .foregroundColor(isNotified ? RSMSTheme.Colors.textSecondary : .white)
                        .cornerRadius(8)
                    }
                    .disabled(isNotified)
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
    
    private func notifyManager(for order: CustomerOrder) {
        guard let storeId = appState.currentStoreID else { return }
        Task {
            do {
                let managerId = try await shipmentService.getStoreManager(storeId: storeId)
                try await shipmentService.createTransferTask(storeId: storeId, managerId: managerId, orderNumber: order.orderNumber)
                
                await MainActor.run {
                    notifiedOrders.insert(order.id)
                    notifyMessage = "Manager has been notified to initiate a transfer for Order #\(order.orderNumber.prefix(8).uppercased()) due to low stock."
                    showNotifyAlert = true
                }
            } catch {
                print("Error notifying manager: \(error)")
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
    
    @State private var expandedProductId: UUID? = nil
    
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
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    if expandedProductId == item.id {
                        expandedProductId = nil
                    } else {
                        expandedProductId = item.id
                    }
                }
            }) {
                HStack(spacing: 16) {
                    // Product Image
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(RSMSTheme.Colors.border.opacity(0.3))
                            .frame(width: 70, height: 70)
                        
                        if let url = resolvePublicImageUrl(for: item.product?.imageUrl ?? item.productImageUrl) {
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
                            .multilineTextAlignment(.leading)
                        
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
                    
                    Image(systemName: expandedProductId == item.id ? "chevron.up" : "chevron.down")
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(12)
            }
            
            if expandedProductId == item.id, let product = item.product {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(RSMSTheme.Colors.borderLight)
                    
                    if let desc = product.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 13))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                            .padding(.bottom, 4)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if let cat = product.category {
                                detailPill(title: "Category", value: cat)
                            }
                            if let mat = product.material, !mat.isEmpty {
                                detailPill(title: "Gender", value: mat)
                            }
                            if let country = product.originCountry, !country.isEmpty {
                                detailPill(title: "Region", value: country)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                    
                    if let notes = product.craftsmanshipNotes, !notes.isEmpty {
                        Text("Craftsmanship: \(notes)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }
    
    private func detailPill(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(title):")
                .foregroundColor(RSMSTheme.Colors.textTertiary)
            Text(value)
                .foregroundColor(.white)
        }
        .font(.system(size: 11, weight: .medium))
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RSMSTheme.Colors.border.opacity(0.3))
        .cornerRadius(6)
    }
}

// MARK: - Image Helper
fileprivate func resolvePublicImageUrl(for path: String?) -> URL? {
    guard let path = path, !path.isEmpty else { return nil }
    if path.hasPrefix("http") { return URL(string: path) }
    let supabaseProjectID = "https://bdgwzkpteyxhlgprlmye.supabase.co"
    let bucketName = "product-images"
    return URL(string: "\(supabaseProjectID)/storage/v1/object/public/\(bucketName)/\(path)")
}
