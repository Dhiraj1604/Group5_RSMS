//
//  ICAlertsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Alerts tab (Task 17).
//  Displays all low-stock items across every store with
//  luxury card UI and search filtering. Tapping an alert
//  navigates to a detail view with product image and description.
//

import SwiftUI

struct ICAlertsTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = ICAlertsViewModel()
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // KPI Header
                    kpiSection
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.top, RSMSTheme.Spacing.sm)
                        .padding(.bottom, RSMSTheme.Spacing.md)

                    // Search Bar
                    searchBar
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.bottom, RSMSTheme.Spacing.md)

                    Divider()
                        .background(Color.white.opacity(0.06))

                    // Content
                    ZStack {
                        if viewModel.isLoading {
                            loadingState
                        } else if viewModel.isEmpty {
                            emptyState
                        } else {
                            alertList
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
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
            .task {
                await viewModel.loadAlerts()
                withAnimation(.easeOut(duration: 0.5)) { animateIn = true }
            }
            .alert("Database Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - KPI Section

    private var kpiSection: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            kpiPill(
                title: "Total Alerts",
                value: "\(viewModel.totalAlertCount)",
                icon: "exclamationmark.triangle.fill",
                color: RSMSTheme.Colors.warning
            )
            kpiPill(
                title: "Critical",
                value: "\(viewModel.criticalCount)",
                icon: "xmark.octagon.fill",
                color: RSMSTheme.Colors.error
            )
        }
    }

    private func kpiPill(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)

            ZStack(alignment: .leading) {
                if viewModel.searchText.isEmpty {
                    Text("Search products, SKUs, stores…")
                        .font(.system(size: 15))
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.6))
                }
                TextField("", text: $viewModel.searchText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .tint(RSMSTheme.Colors.accentGold)
            }

            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Alert List

    private var alertList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredAlerts.enumerated()), id: \.element.id) { index, alert in
                    NavigationLink(destination: LowStockAlertDetailView(alert: alert)) {
                        LowStockAlertCard(alert: alert)
                    }
                    .buttonStyle(.plain)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 18)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.06),
                        value: animateIn
                    )
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
        .refreshable {
            await viewModel.loadAlerts()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(RSMSTheme.Colors.accentGold)
                .scaleEffect(1.5)
            Text("Scanning inventory…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.success.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(RSMSTheme.Colors.success)
            }
            VStack(spacing: 8) {
                Text(viewModel.searchText.isEmpty ? "All Stock Healthy" : "No Results")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text(viewModel.searchText.isEmpty
                     ? "No inventory items are below the\nlow-stock threshold right now."
                     : "Try adjusting your search term\nto find what you're looking for.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation { viewModel.searchText = "" }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Clear Search")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.Colors.goldGradient)
                    .cornerRadius(50)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

#Preview {
    ICAlertsTab()
        .environment(AppState())
}
