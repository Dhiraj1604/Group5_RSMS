//
//  ICStockTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Stock Overview tab (Task 16).
//  Displays stock level summary cards, low-stock alerts,
//  and warehouse metrics. Serves as the primary landing tab.
//

import SwiftUI

struct ICStockTab: View {
    @Environment(AppState.self) private var appState
    @State private var showProductsList = false
    @State private var lowStockCount: Int = 0
    @State private var isLoadingLowStock: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        stockKPISection
                        stockDetailsSection
                        stockCheckEntryCard
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle("Stock")
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
        }
    }

    // MARK: - Stock KPIs

        private var stockKPISection: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: RSMSTheme.Spacing.md) {
                // Total Items — tappable, navigates to ProductsListView
                NavigationLink(destination: ProductsListView()) {
                    stockKPICard(
                        title: "Total Items",
                        value: appState.isLoadingProducts
                            ? "…"
                            : "\(appState.products.count)",
                        icon: "shippingbox.fill",
                        color: RSMSTheme.Colors.accentGold
                    )
                }
                .buttonStyle(.plain)

                stockKPICard(
                    title: "Low Stock",
                    value: isLoadingLowStock ? "…" : "\(lowStockCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: RSMSTheme.Colors.warning
                )
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                NavigationLink(destination: ProductsListView(showOnlyInRepair: true)) {
                    stockKPICard(
                        title: "In Repair",
                        value: appState.isLoadingProducts ? "…" : "\(appState.products.filter { $0.inRepair }.count)",
                        icon: "wrench.and.screwdriver.fill",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
                stockKPICard(
                    title: "Categories",
                    value: appState.isLoadingProducts ? "…" : "\(Set(appState.products.map { $0.category }).count)",
                    icon: "tag.fill",
                    color: RSMSTheme.Colors.accentGoldLight
                )
            }
        }
        .task {
            await appState.fetchProducts()
            await appState.fetchTotalInventoryCount(storeId: appState.assignedStoreId)
            await fetchLowStock()
        }
    }

    private func fetchLowStock() async {
        isLoadingLowStock = true
        do {
            let alerts: [LowStockAlert]
            if let storeId = appState.assignedStoreId {
                alerts = try await LowStockService.shared.fetchLowStockAlerts(forStore: storeId)
            } else {
                alerts = try await LowStockService.shared.fetchAllLowStockAlerts()
            }
            lowStockCount = alerts.count
        } catch {
            print("Failed to fetch low stock alerts: \(error)")
        }
        isLoadingLowStock = false
    }


    private func stockKPICard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
        }
        .cardStyle()
    }

    // MARK: - Stock Details

    private var stockDetailsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Warehouse Overview")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            VStack(spacing: RSMSTheme.Spacing.sm) {
                stockRow(label: "Total SKUs Tracked", value: "\(appState.products.count)")
                stockRow(label: "Total Inventory Units", value: "\(appState.totalInventoryCount)")
                stockRow(label: "Items Below Reorder Level", value: isLoadingLowStock ? "…" : "\(lowStockCount)")
                stockRow(label: "Last Audit Date", value: Date().formatted(.dateTime.month().day().year()))
            }
            .cardStyle()
        }
    }

    // MARK: - Stock Check Entry Card

    private var stockCheckEntryCard: some View {
        NavigationLink(destination: StockCheckView()) {
            HStack(spacing: RSMSTheme.Spacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "checklist")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Stock Check")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text("Compare expected vs. actual counts & resolve discrepancies")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.accentGoldDark)
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .fill(RSMSTheme.Colors.backgroundDeep)
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                            .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.08), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private func stockRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .padding(.vertical, RSMSTheme.Spacing.xs)
    }
}

#Preview {
    ICStockTab()
        .environment(AppState())
}
