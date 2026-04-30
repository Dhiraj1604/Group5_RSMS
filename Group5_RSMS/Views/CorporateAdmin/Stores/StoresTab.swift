//
//  StoresTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Stores tab. SPRINT 1 CORE FEATURE.
//  Lists and registers boutique store locations.
//

import SwiftUI

struct StoresTab: View {
    @Environment(AppState.self) private var appState
    @State private var showAddStore = false
    @State private var searchText = ""
    @State private var filterActive: Bool? = nil
    @State private var isLoading = false              // ← NEW
    @State private var showingProfile = false

    private var filteredStores: [Store] {
        var result = appState.stores
        if !searchText.isEmpty {
            result = result.filter { store in
                store.name.localizedCaseInsensitiveContains(searchText) ||
                store.code.localizedCaseInsensitiveContains(searchText) ||
                store.city.localizedCaseInsensitiveContains(searchText) ||
                store.region.localizedCaseInsensitiveContains(searchText)
            }
        }
        if let active = filterActive {
            result = result.filter { $0.isActive == active }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                if isLoading {                         // ← NEW
                    loadingState
                } else if appState.stores.isEmpty {
                    emptyState
                } else {
                    storesList
                }
            }
            .navigationTitle("Stores")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            showAddStore = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("Add Store")
                        
                        Button {
                            showingProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("My Profile")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search stores...")
            .sheet(isPresented: $showAddStore) {
                AddStoreView()
            }
            .sheet(isPresented: $showingProfile) {
                AdminProfileView()
                    .presentationDetents([.large])
            }
            .alert("Error", isPresented: .constant(appState.storeError != nil)) {
                Button("OK") { appState.storeError = nil }
            } message: {
                Text(appState.storeError ?? "")
            }
            .task {
                guard appState.stores.isEmpty else { return }  // ← skip if already loaded
                isLoading = true
                await appState.loadStores()
                isLoading = false
            }
        }
    }

    // MARK: - Loading State                           // ← NEW
    private var loadingState: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: RSMSTheme.Colors.accentGold))
                .scaleEffect(1.4)
            Text("Loading Stores...")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.5))
            }
            VStack(spacing: RSMSTheme.Spacing.sm) {
                Text("No Stores Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("Register your first boutique location to\nstart managing inventory, staff, and sales.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showAddStore = true
            } label: {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Register First Boutique")
                }
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.horizontal, RSMSTheme.Spacing.xxxl)
        }
    }
    // MARK: - Stores List
    private var storesList: some View {
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.md) {
                filterChips
                HStack {
                    Text("\(filteredStores.count) store\(filteredStores.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, RSMSTheme.Spacing.xs)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20)], spacing: 24) {
                    ForEach(filteredStores) { store in
                        NavigationLink(value: store) {
                            BoutiqueStoreCard(store: store)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, RSMSTheme.Spacing.sm)
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.md)
            .padding(.bottom, RSMSTheme.Spacing.xxl)
        }
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
        }
    }

    // MARK: - Boutique Store Card
    struct BoutiqueStoreCard: View {
        let store: Store
        
        var body: some View {
            ZStack(alignment: .bottomLeading) {
                // 1. Full-Bleed Background Image (Smart Discovery)
                ZStack {
                    if let imagePath = store.imageUrl, imagePath.hasPrefix("http") {
                        // Remote Image
                        AsyncImage(url: URL(string: imagePath)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill().blur(radius: 3)
                            case .empty, .failure:
                                fallbackImage
                            @unknown default:
                                fallbackImage
                            }
                        }
                    } else {
                        // Local Asset Discovery
                        // Priority: 1. Database value, 2. Store Name, 3. City
                        let assetName = store.imageUrl ?? store.name
                        
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 3)
                            .overlay {
                                // Secondary fallback if Store Name doesn't exist in assets
                                Image(store.city)
                                    .resizable()
                                    .scaledToFill()
                                    .blur(radius: 3)
                            }
                            .overlay {
                                // Final fallback: The "building" icon if no images are found
                                if UIImage(named: assetName) == nil && UIImage(named: store.city) == nil {
                                    fallbackImage
                                }
                            }
                    }
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .clipped()
                
                // 2. Luxurious Overlays for Maximum Readability
                ZStack {
                    // Darken overall to make white text pop
                    Color.black.opacity(0.35)
                    
                    VStack {
                        Spacer()
                        // Stronger bottom gradient for text contrast
                        LinearGradient(
                            colors: [.black.opacity(0.6), .black.opacity(0.3), .clear],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                        .frame(height: 160)
                    }
                    
                    // Signature Dot Texture
                    Canvas { context, size in
                        let spacing: CGFloat = 12
                        let dotSize: CGFloat = 1.0
                        for y in stride(from: spacing/2, through: size.height, by: spacing) {
                            for x in stride(from: spacing/2, through: size.width, by: spacing) {
                                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.12)))
                            }
                        }
                    }
                    .blendMode(.plusLighter)
                }
                
                // 3. Typography & Badges
                VStack(alignment: .leading, spacing: 0) { // ← Added alignment: .leading
                    // Top Row: Status Badge only
                    HStack(alignment: .top) {
                        Spacer()
                        
                        // Active Badge (Simple Dot)
                        Circle()
                            .fill(store.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                            .frame(width: 8, height: 8)
                            .shadow(color: .black.opacity(0.5), radius: 3)
                    }
                    
                    Spacer()
                    
                    // Bottom Row: Store Name & Location (with Pin)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.name)
                            .font(.custom("HelveticaNeue-Bold", size: 28))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .shadow(color: .black.opacity(0.9), radius: 4)
                        
                        HStack(spacing: 6) {
                            Text("📍")
                                .font(.system(size: 14))
                            Text("\(store.city), \(store.country)")
                                .font(.custom("HelveticaNeue-Medium", size: 14))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .shadow(color: .black.opacity(0.8), radius: 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // ← Force leading alignment
                }
                .padding(24)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), .clear, RSMSTheme.Colors.accentGold.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
        }
        
        private var fallbackHeader: some View {
            RSMSTheme.Colors.backgroundDeep
                .overlay(
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.2))
                )
        }

        private var fallbackImage: some View {
            RSMSTheme.Colors.backgroundDeep
                .overlay(
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.2))
                )
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                filterChip(label: "All", isSelected: filterActive == nil) { filterActive = nil }
                filterChip(label: "Active", isSelected: filterActive == true) { filterActive = true }
                filterChip(label: "Inactive", isSelected: filterActive == false) { filterActive = false }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textSecondary)
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundDeep)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
        }
    }
}

#Preview("Empty") {
    StoresTab()
        .environment(AppState())
}

#Preview("With Stores") {
    let state = AppState()
    state.stores = Store.samples
    return StoresTab()
        .environment(state)
}
