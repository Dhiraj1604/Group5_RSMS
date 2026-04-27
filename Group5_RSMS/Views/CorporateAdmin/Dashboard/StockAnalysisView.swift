//
//  StockAnalysisView.swift
//  Group5_RSMS
//
//  Corporate Admin — Stock Analysis per store.
//  Shows inventory levels for each SKU with low-stock / overstock flags.
//  Redesigned for a premium, extremely luxurious aesthetic.
//

import SwiftUI
import Supabase
struct StockAnalysisView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let store: Store

    @StateObject private var viewModel = StockAnalysisViewModel()
    @State private var selectedItem: StockAnalysisViewModel.StockItem?
    @State private var showTransferSheet = false
    @State private var showReplenishAlert = false
    @State private var transferSources: [TransferSource] = []
    @State private var isLoadingSources = false
    
    @Namespace private var filterAnimation

    var body: some View {
        ZStack {
            // Refined Luxury Background
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            // Elegant background accents
            Circle()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                .blur(radius: 100)
                .frame(width: 500, height: 500)
                .offset(x: 200, y: -200)

            Circle()
                .fill(Color.orange.opacity(0.05))
                .blur(radius: 150)
                .frame(width: 400, height: 400)
                .offset(x: -200, y: 300)

            if viewModel.isLoading && viewModel.inventoryItems.isEmpty {
                loadingView
            } else if viewModel.inventoryItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        summarySection
                        stockGrid
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.sm)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationTitle(store.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.automatic, for: .navigationBar)
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
                .presentationDetents([.fraction(0.75), .large])
                .presentationCornerRadius(32)
                .presentationBackground(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
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
                .scaleEffect(1.5)
            Text("Analyzing Inventory...")
                .font(.system(.subheadline, design: .serif).italic())
                .foregroundStyle(RSMSTheme.Colors.accentGold)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            Image(systemName: "shippingbox.and.arrow.backward")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.5))
            Text("No Products Listed")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, RSMSTheme.Spacing.xxl)
    }

    // MARK: - Summary Cards
    private var summarySection: some View {
        let s = viewModel.summary
        
        let columns = horizontalSizeClass == .regular 
            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
            
        return LazyVGrid(columns: columns, spacing: RSMSTheme.Spacing.md) {
            summaryCard(title: "Total SKUs", value: "\(s.total)", icon: "shippingbox.fill", color: .white, filter: .all)
            summaryCard(title: "Low Stock", value: "\(s.low)", icon: "exclamationmark.triangle.fill", color: Color.orange, filter: .low)
            summaryCard(title: "Overstock", value: "\(s.overstock)", icon: "arrow.up.circle.fill", color: Color(red: 0.2, green: 0.8, blue: 0.3), filter: .overstock)
            summaryCard(title: "Out of Stock", value: "\(s.outOfStock)", icon: "xmark.circle.fill", color: Color(red: 0.9, green: 0.2, blue: 0.2), filter: .outOfStock)
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color, filter: StockAnalysisViewModel.StockFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                viewModel.selectedFilter = filter
            }
        } label: {
            VStack(spacing: RSMSTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? color : color.opacity(0.6))
                    .padding(.bottom, 2)
                
                Text(value)
                    .font(.custom("HelveticaNeue-Bold", size: 32))
                    .foregroundStyle(isSelected ? color : color.opacity(0.8))
                    .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 4, x: 0, y: 2)
                
                Text(title.uppercased())
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .tracking(1.2)
                    .foregroundStyle(isSelected ? color : color.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                LinearGradient(
                    colors: isSelected 
                        ? [RSMSTheme.Colors.backgroundElevated, RSMSTheme.Colors.backgroundElevated.opacity(0.8)]
                        : [RSMSTheme.Colors.backgroundDeep, RSMSTheme.Colors.backgroundDeep.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? color.opacity(0.5) : RSMSTheme.Colors.borderLight,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? color.opacity(0.15) : Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Row
    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSTheme.Spacing.md) {
                ForEach(StockAnalysisViewModel.StockFilter.allCases, id: \.self) { filter in
                    let isSelected = viewModel.selectedFilter == filter
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textSecondary)
                            .background(
                                ZStack {
                                    if isSelected {
                                        Capsule()
                                            .fill(RSMSTheme.Colors.accentGold)
                                            .matchedGeometryEffect(id: "ActiveFilter", in: filterAnimation)
                                    } else {
                                        Capsule()
                                            .fill(Color.white.opacity(0.05))
                                    }
                                }
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : .white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }

    private var stockGrid: some View {
        let columns = horizontalSizeClass == .regular
            ? [GridItem(.adaptive(minimum: 360), spacing: RSMSTheme.Spacing.lg)]
            : [GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: RSMSTheme.Spacing.lg) {
            ForEach(viewModel.filteredItems) { item in
                stockItemCard(item)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredItems.count)
    }

    private func stockItemCard(_ item: StockAnalysisViewModel.StockItem) -> some View {
        let status = item.stockStatus
        let statusColor: Color = {
            switch status {
            case .outOfStock: return Color(red: 0.9, green: 0.2, blue: 0.2) // Red
            case .low: return Color.orange // Orange
            case .normal: return Color(red: 0.2, green: 0.8, blue: 0.3) // Green
            case .overstock: return Color(red: 0.2, green: 0.8, blue: 0.3) // Green
            }
        }()

        return VStack(spacing: 0) {
            // Top section: Content with Image Background
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.category.uppercased())
                            .font(.custom("HelveticaNeue-Bold", size: 12))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .tracking(2)
                            .shadow(color: .black.opacity(0.8), radius: 2)
                            
                        Text(item.productName)
                            .font(.custom("HelveticaNeue-Bold", size: 26))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.6)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .shadow(color: .black.opacity(0.8), radius: 4)
                            
                        Text("SKU: \(item.sku)")
                            .font(.custom("HelveticaNeue", size: 12))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .shadow(color: .black.opacity(0.8), radius: 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 32)
                    
                    // Massive beautiful quantity
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(item.stockQuantity)")
                            .font(.custom("HelveticaNeue-Bold", size: 58))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.8), radius: 5)
                        
                        Text("UNITS")
                            .font(.custom("HelveticaNeue-Bold", size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(1.5)
                            .shadow(color: .black.opacity(0.8), radius: 2)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
                // Status indicator (Moved to Top Right)
                Text(status.rawValue.uppercased())
                    .font(.custom("HelveticaNeue-CondensedBold", size: 10))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .foregroundStyle(statusColor)
                    .background(statusColor.opacity(0.25))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(statusColor.opacity(0.5), lineWidth: 1.5))
                    .padding(16)
            }
            .frame(height: 220, alignment: .bottom) // Fixed height for the image area
            .background {
                // Background Image
                if let urlString = item.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.black.opacity(0.8)
                        }
                    }
                    .blur(radius: 2)
                    .overlay(
                        ZStack {
                            Color.black.opacity(0.75) // Even darker overall overlay for maximum readability
                            
                            // Bottom Golden Glow (More Intense)
                            VStack {
                                Spacer()
                                LinearGradient(
                                    colors: [RSMSTheme.Colors.accentGold.opacity(0.5), .clear],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                .frame(height: 120)
                            }
                        }
                    )
                    .clipped()
                    .overlay(
                        // Subtle luxurious cross-hatch texture
                        Canvas { context, size in
                            let spacing: CGFloat = 10
                            for x in stride(from: -size.height, through: size.width, by: spacing) {
                                var path = Path()
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                                context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 0.5)
                            }
                            for x in stride(from: 0, through: size.width + size.height, by: spacing) {
                                var path = Path()
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                                context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 0.5)
                            }
                        }
                        .blendMode(.overlay)
                    )
                } else {
                    Color.black.opacity(0.8)
                        .overlay(
                            Image(systemName: "bag.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.1))
                        )
                }
            }
            
            // Action Footer
            if status == .overstock || status == .low || status == .outOfStock {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    selectedItem = item
                    if status == .overstock {
                        Task { await loadTransferSources(for: item) }
                    } else {
                        showReplenishAlert = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(status == .overstock ? "INITIATE TRANSFER" : "REQUEST REPLENISHMENT")
                            .font(.custom("HelveticaNeue", size: 14))
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [statusColor.opacity(0.15), statusColor.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .foregroundStyle(statusColor)
                    .overlay(
                        Rectangle().frame(height: 1).foregroundStyle(statusColor.opacity(0.3)),
                        alignment: .top
                    )
                }
                .buttonStyle(.plain)
            } else {
                // To keep cards relatively even, add a subtle base
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 16)
            }
        }
        .background(RSMSTheme.Colors.backgroundPrimary.opacity(0.5)) // Base background
        .clipShape(RoundedRectangle(cornerRadius: 24)) // Clip entire card content
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .clear, statusColor.opacity(0.3)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 15, y: 8)
        .shadow(color: statusColor.opacity(0.15), radius: 30, y: 10)
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
    @State private var quantity: Int = 1
    @State private var selectedSourceIndex: Int? = nil
    @State private var isTransferring = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xxl) {
                        
                        // Header info
                        VStack(alignment: .center, spacing: 8) {
                            Text("TRANSFER INITIATION")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .tracking(2)
                            
                            Text(item.productName)
                                .font(.system(.title2, design: .serif))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                
                            Text("OVERSTOCK: \(item.stockQuantity) UNITS AVAILABLE")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, RSMSTheme.Spacing.xl)

                        // Destination stores
                        if sources.isEmpty {
                            VStack(spacing: RSMSTheme.Spacing.md) {
                                Image(systemName: "building.2.crop.circle")
                                    .font(.system(size: 48, weight: .ultraLight))
                                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                Text("No boutiques currently require replenishment for this item.")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                                Text("SELECT DESTINATION")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    .tracking(1)

                                ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedSourceIndex = index
                                        }
                                        let impact = UISelectionFeedbackGenerator()
                                        impact.selectionChanged()
                                    } label: {
                                        HStack(spacing: RSMSTheme.Spacing.md) {
                                            // Custom animated checkmark
                                            ZStack {
                                                Circle()
                                                    .strokeBorder(selectedSourceIndex == index ? RSMSTheme.Colors.accentGold : .white.opacity(0.2), lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                
                                                if selectedSourceIndex == index {
                                                    Circle()
                                                        .fill(RSMSTheme.Colors.accentGold)
                                                        .frame(width: 12, height: 12)
                                                        .transition(.scale.combined(with: .opacity))
                                                }
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(source.storeName)
                                                    .font(.system(size: 16, weight: .medium, design: .serif))
                                                    .foregroundStyle(.white)
                                                Text("\(source.storeCity) · Needs \(source.availableQuantity) units")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(20)
                                        .background(selectedSourceIndex == index
                                            ? RSMSTheme.Colors.accentGold.opacity(0.1)
                                            : .white.opacity(0.05))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedSourceIndex == index
                                                    ? RSMSTheme.Colors.accentGold.opacity(0.5)
                                                    : .white.opacity(0.05), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Quantity Stepper
                            VStack(alignment: .center, spacing: RSMSTheme.Spacing.md) {
                                Text("QUANTITY")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    .tracking(1)

                                HStack(spacing: 30) {
                                    Button {
                                        if quantity > 1 { quantity -= 1 }
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.title2)
                                            .foregroundStyle(quantity > 1 ? .white : RSMSTheme.Colors.textTertiary)
                                            .frame(width: 50, height: 50)
                                            .background(.white.opacity(0.05))
                                            .clipShape(Circle())
                                    }
                                    .disabled(quantity <= 1)

                                    Text("\(quantity)")
                                        .font(.system(size: 40, weight: .light, design: .rounded))
                                        .foregroundStyle(.white)
                                        .frame(width: 80)

                                    Button {
                                        // Cap at available overstock or arbitrary large number if unconstrained
                                        quantity += 1
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .frame(width: 50, height: 50)
                                            .background(.white.opacity(0.05))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.vertical, 10)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(RSMSTheme.Colors.error)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            // Transfer button
                            Button {
                                let impact = UIImpactFeedbackGenerator(style: .heavy)
                                impact.impactOccurred()
                                Task { await executeTransfer() }
                            } label: {
                                HStack {
                                    if isTransferring {
                                        ProgressView().tint(.black)
                                    }
                                    Text(isTransferring ? "AUTHORIZING..." : "AUTHORIZE TRANSFER")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .tracking(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(selectedSourceIndex == nil ? RSMSTheme.Colors.textTertiary : RSMSTheme.Colors.accentGold)
                                .foregroundStyle(selectedSourceIndex == nil ? .white.opacity(0.5) : .black)
                                .cornerRadius(100)
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedSourceIndex == nil || isTransferring || quantity < 1)
                            .animation(.easeIn, value: selectedSourceIndex)
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .alert("Transfer Authorized", isPresented: $showSuccess) {
                Button("Done") {
                    onComplete()
                    dismiss()
                }
            } message: {
                Text("Stock movement has been logged and initiated successfully.")
            }
        }
    }

    private func executeTransfer() async {
        guard let sourceIndex = selectedSourceIndex, quantity > 0 else {
            errorMessage = "Invalid transfer parameters."
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
                quantity: quantity,
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var storeSKUCounts: [UUID: Int] = [:]

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            // Ambient luxury lighting
            Ellipse()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                .blur(radius: 120)
                .frame(width: 600, height: 400)
                .offset(y: -200)

            if appState.stores.isEmpty {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    Image(systemName: "building.2")
                        .font(.system(size: 64, weight: .ultraLight))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.4))
                    Text("No Boutiques Available")
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(.white)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xl) {
                        // Store Grid
                        let columns = horizontalSizeClass == .regular
                            ? [GridItem(.adaptive(minimum: 220), spacing: RSMSTheme.Spacing.lg)]
                            : [GridItem(.flexible())]
                        
                        LazyVGrid(columns: columns, spacing: RSMSTheme.Spacing.lg) {
                            ForEach(appState.stores) { store in
                                NavigationLink(destination: StockAnalysisView(store: store)) {
                                    storeCard(store)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.lg)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationTitle("Stock Analysis")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.automatic, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await fetchSKUCounts() }
    }

    private func storeCard(_ store: Store) -> some View {
        let skuCount = storeSKUCounts[store.id] ?? 0
        return ZStack {
            // Premium Obsidian Material Gradient
            LinearGradient(
                colors: [Color(white: 0.08), Color(white: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // High-Visibility 'Guilloché' Dot Texture
            Canvas { context, size in
                let spacing: CGFloat = 14
                let dotSize: CGFloat = 1.5
                for y in stride(from: spacing/2, through: size.height, by: spacing) {
                    for x in stride(from: spacing/2, through: size.width, by: spacing) {
                        let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: rect), with: .color(RSMSTheme.Colors.accentGold.opacity(0.3)))
                    }
                }
            }
            .blendMode(.plusLighter)
            
            // Soft Gold Dispersion (Under-glow)
            VStack {
                Spacer()
                LinearGradient(
                    colors: [RSMSTheme.Colors.accentGold.opacity(0.1), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 80)
            }

            VStack(alignment: .leading, spacing: 0) {
                // Top Header: Name and Badge
                HStack(alignment: .top) {
                    Text(store.name)
                        .font(.custom("HelveticaNeue-Bold", size: 22))
                        .foregroundStyle(.white)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    // Status Badge
                    if store.isActive == true {
                        statusBadge(text: "ACTIVE", color: Color(red: 0.2, green: 0.8, blue: 0.3))
                    } else {
                        statusBadge(text: "INACTIVE", color: Color(red: 0.9, green: 0.2, blue: 0.2))
                    }
                }
                .padding(24)
                
                Spacer(minLength: 0)
                
                // Location and SKUs
                VStack(alignment: .leading, spacing: 10) {
                    Text(locationForStore(store).uppercased())
                        .font(.custom("HelveticaNeue-Bold", size: 14))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .tracking(3)
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ACTIVE SKUs")
                                .font(.custom("HelveticaNeue-Bold", size: 11))
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                .tracking(1.5)
                            Text("\(skuCount)")
                                .font(.custom("HelveticaNeue-Bold", size: 40))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
                .padding(24)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 15, y: 10)
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("HelveticaNeue-Bold", size: 10))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }

    private func locationForStore(_ store: Store) -> String {
        return store.city
    }

    private func fetchSKUCounts() async {
        do {
            struct InventoryCount: Decodable {
                let store_id: UUID
            }
            #if canImport(Supabase)
            let rows: [InventoryCount] = try await SupabaseManager.shared.client
                .from("inventory")
                .select("store_id")
                .execute()
                .value
            
            var counts: [UUID: Int] = [:]
            for row in rows {
                counts[row.store_id, default: 0] += 1
            }
            self.storeSKUCounts = counts
            #endif
        } catch {
            print("Failed to fetch SKU counts: \(error)")
        }
    }
}
