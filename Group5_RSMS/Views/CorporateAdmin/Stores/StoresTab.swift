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

    private var filteredStores: [Store] {
        var result = appState.stores
        if !searchText.isEmpty {
            result = result.filter { store in
                store.name.localizedCaseInsensitiveContains(searchText) ||
                store.code.localizedCaseInsensitiveContains(searchText) ||
                store.city.localizedCaseInsensitiveContains(searchText) ||
                (store.region ?? "").localizedCaseInsensitiveContains(searchText)
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

                if appState.stores.isEmpty {
                    if appState.isLoadingStores {
                        VStack(spacing: RSMSTheme.Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(RSMSTheme.Colors.accentGold)
                            Text("Loading Boutiques...")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                    } else {
                        emptyState
                    }
                } else {
                    storesList
                }
            }
            .navigationTitle("Stores")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddStore = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search stores...")
            .sheet(isPresented: $showAddStore) {
                AddStoreView()
            }
            .task {
                if appState.stores.isEmpty {
                    await appState.fetchStores()
                }
            }
            .refreshable {
                await appState.fetchStores()
            }
            .alert("Error Loading Boutiques", isPresented: Binding<Bool>(
                get: { appState.storeError != nil },
                set: { if !$0 { appState.storeError = nil } }
            )) {
                Button("Retry", role: .cancel) {
                    Task { await appState.fetchStores() }
                }
                Button("Dismiss", role: .none) { }
            } message: {
                Text(appState.storeError ?? "Unknown error occurred.")
            }
        }
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
                    Image(systemName: "plus")
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

                ForEach(filteredStores) { store in
                    NavigationLink(value: store) {
                        storeCard(store: store)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.top, RSMSTheme.Spacing.md)
            .padding(.bottom, RSMSTheme.Spacing.xxl)
        }
        .navigationDestination(for: Store.self) { store in
            StoreDetailView(store: store)
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

    // MARK: - Store Card
    private func storeCard(store: Store) -> some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                     .fill((store.isActive == true)
                          ? RSMSTheme.Colors.accentGold.opacity(0.15)
                          : RSMSTheme.Colors.textTertiary.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "storefront.fill")
                    .font(.title3)
                    .foregroundStyle((store.isActive == true)
                                     ? RSMSTheme.Colors.accentGold
                                     : RSMSTheme.Colors.textTertiary)
            }
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                HStack {
                    Text(store.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text((store.isActive == true) ? "Active" : "Inactive")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle((store.isActive == true) ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                        .padding(.horizontal, RSMSTheme.Spacing.sm)
                        .padding(.vertical, 3)
                        .background(
                            ((store.isActive == true) ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                                .opacity(0.15)
                        )
                        .clipShape(Capsule())
                }
                HStack(spacing: RSMSTheme.Spacing.lg) {
                    Label(store.code, systemImage: "qrcode")
                    Label(store.city, systemImage: "mappin")
                }
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .cardStyle()
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
