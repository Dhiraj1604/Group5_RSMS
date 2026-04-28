//
//  BMInventoryTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Inventory. iOS 26 Liquid Glass & Segmented Cards.
//

import SwiftUI
import Charts

struct BMInventoryTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = BMInventoryViewModel()
    @State private var selectedTabSegment = 0
    @State private var selectedAlert: LowStockAlert? = nil
    
    @State private var isShowingIncomingRequests = false
    @State private var isShowingMyRequests = false
    @State private var productToMove: FastMovingProduct? = nil
    
    @Namespace private var segmentNamespace

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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Native Segmented Control with Enhanced Sizing
                    Picker("Logistics", selection: $selectedTabSegment) {
                        Text("Logistics").tag(0)
                        Text("Strategy").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 24)
                    .background(Color(UIColor.systemGroupedBackground))

                    Divider().opacity(0.5)

                    if selectedTabSegment == 0 {
                        transferList
                    } else {
                        ScrollView(showsIndicators: false) {
                            merchandisingSegment
                        }
                    }
                }
            }
            .navigationTitle("Logistics Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if let storeId = appState.currentStoreID {
                                await viewModel.loadAlerts(forStore: storeId)
                            }
                        }
                    } label: {
                        LiquidBarButton(icon: "arrow.clockwise")
                    }
                }
            }
            .task {
                if appState.stores.isEmpty {
                    await appState.loadStores()
                }
                if let storeId = appState.currentStoreID {
                    await viewModel.loadAlerts(forStore: storeId)
                    await viewModel.loadIncomingRequests(forStore: storeId)
                    await viewModel.loadMyRequests(forStore: storeId)
                }
            }
            .sheet(item: $selectedAlert) { alert in
                TransferSheet(alert: alert, currentStoreId: appState.currentStoreID ?? UUID(), currentStoreName: currentStoreName, viewModel: viewModel)
            }
            .navigationDestination(isPresented: $isShowingIncomingRequests) {
                IncomingRequestsView(currentStoreName: currentStoreName, viewModel: viewModel)
            }
            .navigationDestination(isPresented: $isShowingMyRequests) {
                MyRequestsView(currentStoreName: currentStoreName, viewModel: viewModel)
            }
            .sheet(item: $productToMove) { product in
                FloorQuantitySheet(product: product, storeId: appState.currentStoreID ?? UUID(), viewModel: viewModel)
            }
        }
    }

    // MARK: - Logistics List
    private var transferList: some View {
        List {
            Section {
                storeHeader
                    .listRowInsets(EdgeInsets(top: 12, leading: 24, bottom: 8, trailing: 24))
                    .listRowBackground(Color.clear)
            }

            Section {
                HStack(spacing: 24) {
                    Button { isShowingIncomingRequests = true } label: {
                        LogisticsManagementCard(title: "INBOUND", icon: "tray.and.arrow.down.fill", color: .blue, count: viewModel.incomingRequests.count)
                    }
                    .buttonStyle(.plain)
                    
                    Button { isShowingMyRequests = true } label: {
                        LogisticsManagementCard(title: "OUTBOUND", icon: "paperplane.fill", color: .purple, count: 0)
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 24, bottom: 20, trailing: 24))
                .listRowBackground(Color.clear)
            }

            Section(header: Text("Critical Stock Intelligence").font(.custom("Helvetica", size: 14)).fontWeight(.bold).foregroundColor(.primary).padding(.leading, 12)) {
                if viewModel.alerts.isEmpty {
                    NoDataIntelligence(icon: "checkmark.shield.fill", message: "Inventory levels are currently optimized")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.alerts) { alert in
                        InventoryIntelligenceCard(alert: alert)
                            .listRowInsets(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var merchandisingSegment: some View {
        VStack(spacing: 40) {
            HStack(spacing: 20) {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 64, height: 64)
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                    Image(systemName: "sparkles").font(.title2).foregroundColor(.accentColor)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Merchandising Strategy")
                        .font(.custom("Helvetica", size: 24))
                        .fontWeight(.bold)
                    Text("Automated floor space optimization signals.")
                        .font(.custom("Helvetica", size: 16))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(32)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .padding(.horizontal, 32)
            .padding(.top, 24)

            VStack(alignment: .leading, spacing: 24) {
                Text("High-Velocity Inventory")
                    .font(.custom("Helvetica", size: 20))
                    .fontWeight(.bold)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 20) {
                    ForEach(viewModel.fastMovingProducts.prefix(5)) { product in
                        FastMoverIntelligenceCard(product: product, productToMove: $productToMove)
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer(minLength: 100)
        }
        .task {
            if let storeId = appState.currentStoreID {
                await viewModel.loadMerchandisingInsights(forStore: storeId)
            }
        }
    }

    private var storeHeader: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 60, height: 60)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                Image(systemName: "building.2.fill").font(.title3).foregroundColor(.accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT BOUTIQUE")
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .tracking(1.5)
                    .foregroundColor(.secondary)
                Text(currentStoreName)
                    .font(.custom("Helvetica", size: 22))
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Logistics Components

struct LogisticsManagementCard: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 72, height: 72)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                Image(systemName: icon).font(.title).foregroundColor(color)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.custom("Helvetica", size: 12))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 25, y: -25)
                }
            }
            Text(title)
                .font(.custom("Helvetica", size: 14))
                .fontWeight(.bold)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

struct InventoryIntelligenceCard: View {
    let alert: LowStockAlert
    var body: some View {
        HStack(spacing: 20) {
            AsyncImage(url: URL(string: alert.productImageUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(alert.productName)
                    .font(.custom("Helvetica", size: 20))
                    .fontWeight(.bold)
                Text(alert.productSku)
                    .font(.custom("Helvetica", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(alert.stockQuantity)")
                    .font(.custom("Helvetica", size: 40))
                    .fontWeight(.bold)
                    .foregroundColor(alert.stockQuantity <= 2 ? .red : .orange)
                Text("LEFT")
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

struct FastMoverIntelligenceCard: View {
    let product: FastMovingProduct
    @Binding var productToMove: FastMovingProduct?
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section
            HStack(spacing: 20) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.custom("Helvetica", size: 22))
                        .fontWeight(.bold)
                    Text(product.sku)
                        .font(.custom("Helvetica", size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                Spacer()
                
                Image(systemName: product.trendDirection == .up ? "arrow.up.right.circle.fill" : "minus.circle.fill")
                    .font(.title)
                    .foregroundColor(product.trendDirection == .up ? .green : .orange)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            
            // Bottom Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REC. ACTION")
                        .font(.custom("Helvetica", size: 10))
                        .fontWeight(.black)
                        .foregroundColor(.secondary)
                    Text(product.recommendationText)
                        .font(.custom("Helvetica", size: 16))
                        .fontWeight(.bold)
                }
                Spacer()
                Button { productToMove = product } label: {
                    Text(product.isOnFloor ? "REMOVE" : "PROMOTE")
                        .font(.custom("Helvetica", size: 14))
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(product.isOnFloor ? Color.secondary : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(24)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
    }
}
