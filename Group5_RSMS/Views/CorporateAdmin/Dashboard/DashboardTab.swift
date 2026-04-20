//
//  DashboardTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Dashboard tab with KPI cards and quick stats.
//

import SwiftUI

struct DashboardTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        kpiSection
                        quickStatsSection
                        quickActionsSection
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle("Dashboard")
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

    // MARK: - KPIs
    private var kpiSection: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: RSMSTheme.Spacing.md) {
                kpiCard(title: "Revenue", value: "₹0", icon: "indianrupeesign.circle.fill", color: RSMSTheme.Colors.success)
                kpiCard(title: "Orders", value: "0", icon: "bag.fill", color: RSMSTheme.Colors.accentGold)
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                kpiCard(title: "Active Stores", value: "\(appState.stores.filter { $0.isActive == true }.count)", icon: "building.2.fill", color: RSMSTheme.Colors.accentGoldLight)
                kpiCard(title: "Inventory", value: appState.totalInventoryCount > 0 ? "\(appState.totalInventoryCount)" : "–", icon: "shippingbox.fill", color: RSMSTheme.Colors.accentGoldDark)
            }
        }
    }

    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
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

    // MARK: - Quick Stats
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Quick Overview")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            VStack(spacing: RSMSTheme.Spacing.sm) {
                statRow(label: "Total Stores Registered", value: "\(appState.stores.count)")
                statRow(label: "Active Locations", value: "\(appState.stores.filter { $0.isActive == true }.count)")
                statRow(label: "Total Products", value: "\(appState.products.count)")
                statRow(label: "Inventory Units", value: "\(appState.totalInventoryCount)")
            }
            .cardStyle()
        }
    }

    private func statRow(label: String, value: String) -> some View {
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

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            NavigationLink {
                TaxSettingsView()
            } label: {
                HStack(spacing: RSMSTheme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                            .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "percent")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }

                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                        Text("Tax Settings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)

                        Text("Manage regional tax rules & VAT")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .cardStyle()
            }
        }
    }
}

#Preview {
    DashboardTab()
        .environment(AppState())
}
