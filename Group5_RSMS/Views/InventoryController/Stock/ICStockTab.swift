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

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        stockKPISection
                        stockDetailsSection
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
                    value: "23",
                    icon: "exclamationmark.triangle.fill",
                    color: RSMSTheme.Colors.warning
                )
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                stockKPICard(
                    title: "Pending In",
                    value: "5",
                    icon: "arrow.down.circle.fill",
                    color: RSMSTheme.Colors.success
                )
                stockKPICard(
                    title: "Categories",
                    value: "18",
                    icon: "tag.fill",
                    color: RSMSTheme.Colors.accentGoldLight
                )
            }
        }
        .task {
            await appState.fetchProducts()
        }
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
                stockRow(label: "Items Below Reorder Level", value: "23") // Pending threshold implementation
                stockRow(label: "Last Audit Date", value: Date().formatted(.dateTime.month().day().year()))
            }
            .cardStyle()
        }
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
