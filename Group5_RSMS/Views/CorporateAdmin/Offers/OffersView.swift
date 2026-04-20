//
//  OffersView.swift
//  Group5_RSMS
//
//  Corporate Admin — Offers list: Active & Scheduled tabs.
//  Strictly iOS-native: List + insetGrouped + Picker segmented control.
//

import SwiftUI

// MARK: - OffersView

struct OffersView: View {

    @StateObject private var service = OfferService()
    @State private var selectedTab: OfferTab = .active
    @State private var showCreate    = false
    @State private var offerForDetail: Offer?
    @State private var showErrorAlert = false
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .newest
    @State private var filterCategory: String = "All Categories"
    @State private var filterStoreId: UUID? = nil
    @State private var showPausedOnly = false

    enum OfferTab: String, CaseIterable, Identifiable {
        case active    = "Active"
        case scheduled = "Scheduled"
        case expired   = "Expired"
        var id: Self { self }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case highDiscount = "Highest Discount"
        case lowDiscount = "Lowest Discount"
        var id: Self { self }
    }
    


    private var listedOffers: [Offer] {
        var base: [Offer]
        switch selectedTab {
        case .active: 
            base = service.activeOffers
            if showPausedOnly {
                base = base.filter { $0.computedStatus == .paused }
            } else {
                base = base.filter { $0.computedStatus == .active }
            }
        case .scheduled: base = service.scheduledOffers
        case .expired: base = service.expiredOffers
        }
        
        // Filter Category
        if filterCategory != "All Categories" {
            base = base.filter { $0.applicableTo == filterCategory }
        }
        
        // Filter Store
        if let storeId = filterStoreId {
            base = base.filter { $0.assignedStoreIds.contains(storeId) }
        }
        
        // Search
        if !searchText.isEmpty {
            base = base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sort
        switch sortOption {
        case .newest: base.sort { $0.startDate > $1.startDate }
        case .oldest: base.sort { $0.startDate < $1.startDate }
        case .highDiscount: base.sort { $0.discountValue > $1.discountValue }
        case .lowDiscount: base.sort { $0.discountValue < $1.discountValue }
        }
        
        return base
    }

    init() {
        // Tint the segmented control to match theme
        let a = UISegmentedControl.appearance()
        a.selectedSegmentTintColor = UIColor(RSMSTheme.Colors.accentGold)
        a.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        a.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        a.backgroundColor = UIColor(RSMSTheme.Colors.backgroundElevated)
        
        // Thematic gold for search bar
        UISearchBar.appearance().tintColor = UIColor(RSMSTheme.Colors.accentGold)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor(RSMSTheme.Colors.accentGold)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.lg) {
                // ── Stats / Tabs ───────────────────────────────────────
                statsRow
                    .padding(.top, RSMSTheme.Spacing.sm)

                // ── Sort & Filter ──────────────────────────────────────
                sortAndFilterRow

                // ── Loading indicator ──────────────────────────────────
                if service.isLoading && service.offers.isEmpty {
                    VStack(spacing: RSMSTheme.Spacing.sm) {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                            .scaleEffect(1.2)
                        Text("Loading offers…")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                
                // ── Offers List ────────────────────────────────────────
                else {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                        Text("\(listedOffers.count) \(selectedTab.rawValue) Offer\(listedOffers.count == 1 ? "" : "s")")
                            .font(.custom("Helvetica", size: 14).weight(.medium))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        
                        if listedOffers.isEmpty {
                            emptyRow
                        } else {
                            LazyVStack(spacing: RSMSTheme.Spacing.md) {
                                ForEach(listedOffers) { offer in
                                    SwipeToDeleteWrapper(action: {
                                        service.softDeleteOffer(offer)
                                    }) {
                                        OfferRow(offer: offer)
                                            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                                            .onTapGesture {
                                                offerForDetail = offer
                                            }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100) // Padding for tab bar
        }
        .scrollContentBackground(.hidden)
        .background(RSMSTheme.Colors.backgroundPrimary)
        .navigationTitle("Offers")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search offers...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            // Refresh after creation sheet is dismissed
            service.fetchOffers()
        } content: {
            CreateOfferView(service: service)
        }
        .sheet(item: $offerForDetail) { offer in
            NavigationStack {
                OfferDetailView(offer: offer, service: service)
            }
        }
        .refreshable {
            service.fetchOffers()
            service.fetchStores()
        }
        .onAppear {
            if service.offers.isEmpty {
                service.fetchOffers()
            }
            if service.stores.isEmpty {
                service.fetchStores()
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { service.errorMessage = nil }
        } message: {
            Text(service.errorMessage ?? "An unknown error occurred.")
        }
        .onChange(of: service.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
    }

    // MARK: - Swipe to delete

    private func deleteOffers(at offsets: IndexSet) {
        for index in offsets {
            let offer = listedOffers[index]
            service.softDeleteOffer(offer)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            StatCell(
                value: "\(service.activeOffers.count)",
                label: "Active",
                color: RSMSTheme.Colors.success,
                iconName: "bolt.fill",
                isSelected: selectedTab == .active
            ) { selectedTab = .active }

            StatCell(
                value: "\(service.scheduledOffers.count)",
                label: "Scheduled",
                color: RSMSTheme.Colors.accentGold,
                iconName: "calendar",
                isSelected: selectedTab == .scheduled
            ) { selectedTab = .scheduled }
            
            StatCell(
                value: "\(service.expiredOffers.count)",
                label: "Expired",
                color: Color(red: 1.0, green: 0.5, blue: 0.31), // Coral
                iconName: "clock.fill",
                isSelected: selectedTab == .expired
            ) { selectedTab = .expired }
        }
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
    }

    // MARK: - Sort & Filter Row
    
    private var sortAndFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSTheme.Spacing.md) {
                // Paused Checkbox First
                if selectedTab == .active {
                    Button(action: { showPausedOnly.toggle() }) {
                        HStack {
                            Image(systemName: showPausedOnly ? "checkmark.square.fill" : "square")
                            Text("Paused")
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(showPausedOnly ? RSMSTheme.Colors.accentGold.opacity(0.15) : RSMSTheme.Colors.backgroundElevated)
                        .foregroundStyle(showPausedOnly ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textPrimary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(showPausedOnly ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.borderLight, lineWidth: 1))
                    }
                }
                
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(SortOption.allCases) { opt in Text(opt.rawValue).tag(opt) }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                }
                
                Menu {
                    Picker("Category", selection: $filterCategory) {
                        Text("All Categories").tag("All Categories")
                        Text("Handbags").tag("Handbags")
                        Text("Footwear").tag("Footwear")
                        Text("Accessories").tag("Accessories")
                        Text("Fragrances").tag("Fragrances")
                        Text("Ready-to-wear").tag("Ready-to-wear")
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filterCategory)
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                }
                
                Menu {
                    Picker("Store", selection: $filterStoreId) {
                        Text("All Stores").tag(UUID?(nil))
                        ForEach(service.stores) { store in
                            Text(store.name).tag(UUID?(store.id))
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(filterStoreId == nil ? "All Stores" : (service.stores.first(where: { $0.id == filterStoreId })?.name ?? "Unknown Store"))
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.bottom, RSMSTheme.Spacing.xs)
        }
    }

    // MARK: - Empty state row

    private var emptyRow: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            Image(systemName: selectedTab == .active ? "tag.slash" : (selectedTab == .scheduled ? "clock.badge.xmark" : "archivebox"))
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No \(selectedTab.rawValue.lowercased()) offers")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - StatCell

struct StatCell: View {
    let value: String
    let label: String
    let color: Color
    var iconName: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: RSMSTheme.Spacing.xs) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? color : color.opacity(0.6))
                        .padding(.bottom, 2)
                }
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? color : color.opacity(0.8))
                    .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 4, x: 0, y: 2)
                Text(label.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1.0)
                    .foregroundStyle(isSelected ? color : color.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, RSMSTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: isSelected 
                        ? [RSMSTheme.Colors.backgroundElevated, RSMSTheme.Colors.backgroundElevated.opacity(0.8)]
                        : [RSMSTheme.Colors.backgroundDeep, RSMSTheme.Colors.backgroundDeep.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(RSMSTheme.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(
                        isSelected ? color.opacity(0.5) : RSMSTheme.Colors.borderLight,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? color.opacity(0.15) : Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - OfferRow

struct OfferRow: View {
    let offer: Offer

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        return df
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Accent Color Line
            Rectangle()
                .fill(statusColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header: Name & Status
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(offer.name)
                            .font(.custom("Helvetica", size: 18).weight(.bold))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                            Text(offer.applicableTo ?? "All Products")
                                .font(.custom("Helvetica", size: 12).weight(.medium))
                        }
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                    Spacer()
                    OfferStatusPill(status: offer.computedStatus)
                }
                .padding(RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.backgroundElevated)
                
                Divider()
                    .background(RSMSTheme.Colors.borderLight)
                
                // Footer: Discount & Dates
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DISCOUNT")
                            .font(.custom("Helvetica", size: 10).weight(.bold))
                            .tracking(1.0)
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text(offer.discountLabel)
                            .font(.custom("Helvetica", size: 24).weight(.heavy))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("VALIDITY")
                            .font(.custom("Helvetica", size: 10).weight(.bold))
                            .tracking(1.0)
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(Self.dateFormatter.string(from: offer.startDate)) - \(Self.dateFormatter.string(from: offer.endDate))")
                                .font(.custom("Helvetica", size: 12))
                        }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                }
                .padding(RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.backgroundDeep)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
    
    private var statusColor: Color {
        switch offer.computedStatus {
        case .active: return RSMSTheme.Colors.success
        case .scheduled: return RSMSTheme.Colors.accentGold
        case .expired: return RSMSTheme.Colors.textTertiary
        case .paused: return RSMSTheme.Colors.warning
        }
    }
}

// MARK: - Swipe To Delete Wrapper

struct SwipeToDeleteWrapper<Content: View>: View {
    @State private var offset: CGFloat = 0
    @State private var isDeleted = false
    let action: () -> Void
    let content: () -> Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Delete Background
            ZStack(alignment: .trailing) {
                Rectangle()
                    .fill(Color.red)
                    .cornerRadius(RSMSTheme.Radius.lg)
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .padding(.trailing, RSMSTheme.Spacing.lg + 20)
            }
            
            content()
                .background(RSMSTheme.Colors.backgroundPrimary) // Cover the red background
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Swiping left only (native swipe to delete)
                            if value.translation.width < 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -120 {
                                withAnimation {
                                    offset = -UIScreen.main.bounds.width
                                    isDeleted = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    action()
                                }
                            } else {
                                withAnimation {
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .opacity(isDeleted ? 0 : 1)
    }
}
