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
                        greetingSection
                        kpiSection
                        quickStatsSection
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
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
                        Button {
                            appState.goBackToRoleSelection()
                        } label: {
                            Label("Switch Role", systemImage: "arrow.left.arrow.right")
                        }
                        Button(role: .destructive) {
                            appState.logout()
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

    // MARK: - Greeting
    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)

                Text("Corporate Admin")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
            Spacer()
            Text(Date(), format: .dateTime.weekday(.wide).month().day())
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .padding(.top, RSMSTheme.Spacing.sm)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
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
                kpiCard(title: "Active Stores", value: "\(appState.stores.filter(\.isActive).count)", icon: "building.2.fill", color: RSMSTheme.Colors.accentGoldLight)
                kpiCard(title: "Inventory", value: "–", icon: "shippingbox.fill", color: RSMSTheme.Colors.accentGoldDark)
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
                statRow(label: "Active Locations", value: "\(appState.stores.filter(\.isActive).count)")
                statRow(label: "Avg Order Value", value: "–")
                statRow(label: "Avg Basket Size", value: "–")
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
}

#Preview {
    DashboardTab()
        .environment(AppState())
}
