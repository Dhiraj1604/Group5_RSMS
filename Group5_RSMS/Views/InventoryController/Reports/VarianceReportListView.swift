//
//  VarianceReportListView.swift
//  Group5_RSMS
//
//  Inventory Controller — Full Variance Report list view.
//

import SwiftUI

struct VarianceReportListView: View {
    @Environment(AppState.self) private var appState
    var varianceData: [VarianceReportItem]
    
    @State private var searchText = ""
    
    var filteredVariance: [VarianceReportItem] {
        if searchText.isEmpty {
            return varianceData
        }
        return varianceData.filter { item in
            let productName = item.product?.name ?? ""
            let storeName = item.store?.name ?? ""
            let status = item.status
            return productName.localizedCaseInsensitiveContains(searchText) ||
                   storeName.localizedCaseInsensitiveContains(searchText) ||
                   status.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            if filteredVariance.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(filteredVariance) { item in
                        varianceRow(for: item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: RSMSTheme.Spacing.xs,
                                leading: RSMSTheme.Spacing.lg,
                                bottom: RSMSTheme.Spacing.xs,
                                trailing: RSMSTheme.Spacing.lg
                            ))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Variance Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
        .searchable(text: $searchText, prompt: "Search by product, store or status")
    }
    
    private var emptyView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No records found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }
    
    private func varianceRow(for item: VarianceReportItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product?.name ?? "Unknown Product")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("Store: \(item.store?.name ?? "Current")")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                
                Text(item.status.capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(item.status == "approved" ? RSMSTheme.Colors.success : (item.status == "rejected" ? RSMSTheme.Colors.error : RSMSTheme.Colors.textSecondary))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(item.status == "approved" ? RSMSTheme.Colors.success : (item.status == "rejected" ? RSMSTheme.Colors.error : RSMSTheme.Colors.borderLight), lineWidth: 0.5)
                    )
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Var: \(item.variance > 0 ? "+\(item.variance)" : "\(item.variance)")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(item.variance < 0 ? RSMSTheme.Colors.error : RSMSTheme.Colors.success)
                Text("Exp: \(item.expectedQuantity) • Act: \(item.actualScannedQuantity)")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                Text(item.createdAt.formatted(.dateTime.month().day().year()))
                    .font(.system(size: 10))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}
