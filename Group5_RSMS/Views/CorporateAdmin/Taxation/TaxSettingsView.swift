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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = TaxSettingsViewModel.shared
    @State private var showAddSheet = false
    @State private var editingRule: TaxRule?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Custom Large Title
                HStack {
                    Text("Additional Taxes")
                        .font(.custom("Helvetica-Bold", size: 34))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.top, 20)
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(RSMSTheme.Colors.accentGold)
                        .padding(.top, 100)
                } else if viewModel.taxRules.isEmpty {
                    emptyState
                        .padding(.top, 100)
                } else {
                    // Category Filter Bar
                    filterBar
                    
                    // Rules List
                    LazyVGrid(columns: gridColumns, spacing: RSMSTheme.Spacing.lg) {
                        ForEach(viewModel.filteredRules) { rule in
                            taxRuleCard(for: rule)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                // Subtle ambient glow
                Ellipse()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                    .blur(radius: 120)
                    .frame(width: 500, height: 300)
                    .offset(y: -250)
            }
            .ignoresSafeArea()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddEditTaxView(viewModel: viewModel)
                .presentationDetents([.height(480)])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingRule) { rule in
            AddEditTaxView(viewModel: viewModel, existingRule: rule)
                .presentationDetents([.height(480)])
                .presentationDragIndicator(.visible)
        }
        .task {
            if viewModel.taxRules.isEmpty {
                await viewModel.fetchTaxRules()
            }
        }
    }

    // MARK: - Computed Properties
    
    private var gridColumns: [GridItem] {
        horizontalSizeClass == .regular
            ? [GridItem(.adaptive(minimum: 220), spacing: RSMSTheme.Spacing.lg)]
            : [GridItem(.flexible())]
    }

    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" Filter
                filterCapsule(label: "All", filter: .all)
                
                // Category Filters
                ForEach(ProductCategory.allCases) { category in
                    filterCapsule(
                        label: category.rawValue,
                        icon: category.icon,
                        filter: .category(category)
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    private func filterCapsule(label: String, icon: String? = nil, filter: TaxSettingsViewModel.TaxFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectedFilter = filter
            }
        } label: {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
                
                Text(label)
                    .font(.custom("HelveticaNeue-Bold", size: 13))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? RSMSTheme.Colors.accentGold : Color.white.opacity(0.05))
            )
            .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textSecondary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tax Rule Card
    
    private func taxRuleCard(for rule: TaxRule) -> some View {
        let isActive = viewModel.activeRuleId == rule.id
        let categoryName = rule.category.rawValue
        let ratePercent = String(format: "%.1f", rule.rate * 100)
        let accentColor = RSMSTheme.Colors.accentGold

        return Button {
            editingRule = rule
        } label: {
            ZStack(alignment: .topLeading) {
                // Base Background
                RSMSTheme.Colors.backgroundDeep
                
                // Subtle Radial Glow
                RadialGradient(
                    gradient: Gradient(colors: [accentColor.opacity(0.15), .clear]),
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 250
                )
                
                VStack(alignment: .leading, spacing: 0) {
                    // Top Right: Status Badge
                    HStack {
                        if isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(RSMSTheme.Colors.success)
                                    .frame(width: 6, height: 6)
                                Text("ACTIVE")
                                    .font(.custom("HelveticaNeue-Bold", size: 10))
                                    .foregroundStyle(RSMSTheme.Colors.success)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        }
                        
                        Spacer()
                        
                        // Category Icon
                        Image(systemName: rule.category.icon)
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Rule Name & Category
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.name)
                            .font(.custom("HelveticaNeue-Bold", size: 26))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(categoryName.uppercased())
                            .font(.custom("HelveticaNeue-Medium", size: 12))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            .tracking(1.5)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Middle: Tax Rate
                    VStack(alignment: .leading, spacing: -2) {
                        Text("ADDITIONAL RATE")
                            .font(.custom("HelveticaNeue-Bold", size: 11))
                            .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.8))
                            .tracking(2)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(ratePercent)
                                .font(.custom("HelveticaNeue-Bold", size: 28))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            Text("%")
                                .font(.custom("HelveticaNeue-Bold", size: 14))
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
        .contextMenu {
            Button { editingRule = rule } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { Task { await viewModel.deleteRule(rule) } } label: { Label("Delete", systemImage: "trash") }
        }
    }

    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.06))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.5))
            }
            
            VStack(spacing: 12) {
                Text("No Additional Taxes")
                    .font(.custom("HelveticaNeue-Bold", size: 18))
                    .foregroundStyle(.white)
                
                Text("Create category-specific tax rules that will be applied on top of regional taxes.")
                    .font(.custom("HelveticaNeue", size: 14))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Additional Tax")
                        .font(.custom("HelveticaNeue-Bold", size: 15))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(RSMSTheme.Colors.accentGold)
                .foregroundStyle(.black)
                .clipShape(Capsule())
            }
        }
    }
}
