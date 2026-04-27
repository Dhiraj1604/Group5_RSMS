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
            // Deep obsidian background
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            // Subtle ambient glow
            Ellipse()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                .blur(radius: 120)
                .frame(width: 500, height: 300)
                .offset(y: -250)

            if viewModel.taxRules.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(RSMSTheme.Colors.accentGold)
                } else {
                    emptyState
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary Header
                        summaryHeader
                        
                        // Rules List
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.taxRules.enumerated()), id: \.element.id) { index, rule in
                                taxRuleCard(for: rule)
                                
                                if index < viewModel.taxRules.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.06))
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                        .background(Color(white: 0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationTitle("Tax Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.automatic, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
    }

    // MARK: - Summary Header
    
    private var summaryHeader: some View {
        HStack(spacing: 16) {
            // Total Rules
            summaryMetric(
                value: "\(viewModel.taxRules.count)",
                label: "RULES",
                icon: "doc.text.fill",
                color: RSMSTheme.Colors.accentGold
            )
            
            // Inclusive Count
            summaryMetric(
                value: "\(viewModel.taxRules.filter { $0.isInclusive }.count)",
                label: "INCLUSIVE",
                icon: "checkmark.circle.fill",
                color: Color(red: 0.2, green: 0.8, blue: 0.3)
            )
            
            // Exclusive Count
            summaryMetric(
                value: "\(viewModel.taxRules.filter { !$0.isInclusive }.count)",
                label: "EXCLUSIVE",
                icon: "plus.circle.fill",
                color: Color.orange
            )
        }
    }
    
    private func summaryMetric(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color.opacity(0.7))
            
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 28))
                .foregroundStyle(.white)
            
            Text(label)
                .font(.custom("HelveticaNeue-Bold", size: 9))
                .tracking(1.5)
                .foregroundStyle(color.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(white: 0.06))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Tax Rule Card
    
    private func taxRuleCard(for rule: TaxRule) -> some View {
        let isActive = viewModel.activeRuleId == rule.id
        let store = viewModel.store(for: rule.storeId)
        let locationName = store.map { "\($0.city), \($0.country)" } ?? "Global"
        let ratePercent = String(format: "%.1f", rule.rate * 100)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.setActiveRule(rule)
            }
        } label: {
            HStack(spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(isActive ? RSMSTheme.Colors.accentGold : Color.white.opacity(0.04))
                    .frame(width: 4)
                    .animation(.easeInOut(duration: 0.3), value: isActive)
                
                HStack(spacing: 16) {
                    // Rate badge (Bigger)
                    ZStack {
                        Circle()
                            .fill(isActive ? RSMSTheme.Colors.accentGold.opacity(0.15) : Color.white.opacity(0.04))
                            .frame(width: 70, height: 70)
                        
                        VStack(spacing: 0) {
                            Text(ratePercent)
                                .font(.custom("HelveticaNeue-Bold", size: 24))
                                .foregroundStyle(isActive ? RSMSTheme.Colors.accentGold : .white)
                            Text("%")
                                .font(.custom("HelveticaNeue", size: 12))
                                .foregroundStyle(isActive ? RSMSTheme.Colors.accentGold.opacity(0.7) : .white.opacity(0.5))
                        }
                    }
                    
                    // Rule details
                    VStack(alignment: .leading, spacing: 8) {
                        Text(rule.name)
                            .font(.custom("HelveticaNeue-Bold", size: 22))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 10))
                                Text(locationName)
                                    .font(.custom("HelveticaNeue", size: 14))
                            }
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            
                            // STRATEGIC IMPACT (New Informative Section)
                            HStack(spacing: 6) {
                                Text("IMPACT:")
                                    .font(.custom("HelveticaNeue-Bold", size: 10))
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                                    .tracking(1)
                                
                                let sampleTax = 100000 * rule.rate
                                Text("₹\(Int(sampleTax).formatted()) tax per ₹1.0L")
                                    .font(.custom("HelveticaNeue", size: 12))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side: Type badge + active indicator
                    VStack(alignment: .trailing, spacing: 12) {
                        // Inclusive/Exclusive pill (Bigger)
                        Text(rule.isInclusive ? "INCLUSIVE" : "EXCLUSIVE")
                            .font(.custom("HelveticaNeue-Bold", size: 11))
                            .tracking(1.2)
                            .foregroundStyle(rule.isInclusive ? Color(red: 0.2, green: 0.8, blue: 0.3) : Color.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                (rule.isInclusive ? Color(red: 0.2, green: 0.8, blue: 0.3) : Color.orange).opacity(0.12)
                            )
                            .clipShape(Capsule())
                        
                        // Active indicator
                        if isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(RSMSTheme.Colors.accentGold)
                                    .frame(width: 6, height: 6)
                                Text("ACTIVE")
                                    .font(.custom("HelveticaNeue-Bold", size: 8))
                                    .tracking(1)
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .buttonStyle(.plain)
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
                Text("No Tax Rules Defined")
                    .font(.custom("HelveticaNeue-Bold", size: 18))
                    .foregroundStyle(.white)
                
                Text("Add your first tax rule to begin managing regional tax compliance.")
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
                    Text("Add Tax Rule")
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
