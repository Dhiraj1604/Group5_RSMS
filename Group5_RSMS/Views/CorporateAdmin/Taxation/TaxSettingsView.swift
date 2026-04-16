//
//  TaxSettingsView.swift
//  Group5_RSMS
//
//  Views/CorporateAdmin/Taxation — Tax Rules Management
//  Dynamic list of TaxRule objects with Add (+), Edit, and Swipe-to-Delete.
//  Reads registered boutiques from AppState (Task 1) via the ViewModel.
//

import SwiftUI

// MARK: - View

@available(iOS 16.0, *)
struct TaxSettingsView: View {

    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = TaxSettingsViewModel.shared
    @State private var showAddSheet = false
    @State private var editingRule: TaxRule?

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.taxRules.isEmpty {
                if viewModel.isLoading {
                    VStack(spacing: RSMSTheme.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(RSMSTheme.Colors.accentGold)
                        Text("Loading Tax Rules...")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                } else {
                    emptyState
                }
            } else {
                rulesList
            }
        }
        .navigationTitle("Tax Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(RSMSTheme.Colors.backgroundDeep)
                                .overlay(
                                    Circle()
                                        .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddEditTaxView(viewModel: viewModel)
        }
        .sheet(item: $editingRule) { rule in
            AddEditTaxView(viewModel: viewModel, existingRule: rule)
        }
        .task {
            viewModel.fetchAvailableStores(from: appState)
            if viewModel.taxRules.isEmpty {
                await viewModel.fetchTaxRules()
            }
        }
        .refreshable {
            await viewModel.fetchTaxRules()
        }
        .alert("Error Loading Rules", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Retry", role: .cancel) {
                Task { await viewModel.fetchTaxRules() }
            }
            Button("Dismiss", role: .none) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred.")
        }
    }

    // MARK: - Rules List

    private var rulesList: some View {
        List {
            ForEach(viewModel.taxRules) { rule in
                taxCard(for: rule)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: RSMSTheme.Spacing.sm,
                        leading: RSMSTheme.Spacing.lg,
                        bottom: RSMSTheme.Spacing.sm,
                        trailing: RSMSTheme.Spacing.lg
                    ))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let index = viewModel.taxRules.firstIndex(where: { $0.id == rule.id }) {
                                Task {
                                    await viewModel.deleteRule(rule)
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            editingRule = rule
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(RSMSTheme.Colors.accentGold)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Tax Card

    private func taxCard(for rule: TaxRule) -> some View {
        let isActive = viewModel.activeRuleId == rule.id
        let store = viewModel.store(for: rule.storeId)
        let locationName = store.map { "\($0.city) • \($0.country)" } ?? "Unknown Location"
        let currency = store?.currencyCode ?? "USD"

        return HStack(spacing: RSMSTheme.Spacing.lg) {

            // Active indicator
            Circle()
                .fill(isActive ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textTertiary.opacity(0.3))
                .frame(width: 10, height: 10)
                .shadow(color: isActive ? RSMSTheme.Colors.accentGold.opacity(0.5) : .clear, radius: 4)

            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                // Rule name
                Text(rule.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)

                // Location — prominent gold (Task 3)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10, weight: .bold))
                    Text(locationName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(RSMSTheme.Colors.accentGold)

                // Rate + type row
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    // Rate (with currency context)
                    Text(String(format: "%.3g%%", rule.rate * 100))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSTheme.Colors.accentGoldLight)
                    
                    Text(currency)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSTheme.Colors.textTertiary)

                    Text("•")
                        .foregroundColor(RSMSTheme.Colors.accentGoldDark)

                    // Inclusive / Exclusive
                    Text(rule.isInclusive ? "Inclusive" : "Exclusive")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(rule.isInclusive ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textSecondary)
                        .padding(.horizontal, RSMSTheme.Spacing.sm)
                        .padding(.vertical, RSMSTheme.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(rule.isInclusive
                                      ? RSMSTheme.Colors.accentGold.opacity(0.15)
                                      : RSMSTheme.Colors.textPrimary.opacity(0.1))
                        )
                }
            }

            Spacer()

            // Active toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.setActiveRule(rule)
                }
            } label: {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isActive ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .stroke(
                            isActive
                                ? RSMSTheme.Colors.accentGold.opacity(0.4)
                                : RSMSTheme.Colors.accentGoldDark.opacity(0.2),
                            lineWidth: isActive ? 1.5 : 0.5
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            editingRule = rule
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                    .frame(width: 100, height: 100)

                Image(systemName: "percent")
                    .font(.system(size: 38, weight: .thin))
                    .foregroundColor(RSMSTheme.Colors.accentGoldDark)
            }

            VStack(spacing: RSMSTheme.Spacing.sm) {
                Text("No Tax Rules")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)

                Text("Tap + to add your first regional tax rule.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Tax Rule")
                }
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.horizontal, RSMSTheme.Spacing.xxxl)

            Spacer()
        }
        .padding(.horizontal, RSMSTheme.Spacing.xl)
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview {
    let state: AppState = {
        let s = AppState()
        s.stores = Store.samples
        return s
    }()
    NavigationStack {
        TaxSettingsView()
    }
    .environment(state)
    .preferredColorScheme(.dark)
}
