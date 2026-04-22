//
//  MerchandisingDetailViews.swift
//  Group5_RSMS
//
//  Detail views for merchandising insights.
//

import SwiftUI

// MARK: - Sold Products List

struct SoldProductsListView: View {
    let products: [SoldProduct]
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            if products.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.minus")
                        .font(.system(size: 60))
                        .foregroundStyle(RSMSTheme.Colors.textSecondary.opacity(0.5))
                    Text("No sales recorded this month")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(products) { product in
                            soldProductRow(product)
                        }
                    }
                    .padding(RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Total Sales")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func soldProductRow(_ product: SoldProduct) -> some View {
        HStack(spacing: 16) {
            // Image
            ZStack {
                if let urlString = product.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            RSMSTheme.Colors.backgroundElevated
                        }
                    }
                } else {
                    RSMSTheme.Colors.backgroundElevated
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                
                Text(product.displayQuantity)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", product.totalRevenue))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
        }
        .padding(12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }
}

// MARK: - Fallback Items List

struct FallbackItemsListView: View {
    let items: [InventoryProduct]
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            if items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(RSMSTheme.Colors.success.opacity(0.5))
                    Text("Fresh inventory! No fallback items.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(items) { item in
                            fallbackItemRow(item)
                        }
                    }
                    .padding(RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Fallback Items")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fallbackItemRow(_ item: InventoryProduct) -> some View {
        let daysOnFloor: Int = {
            guard let date = item.last_moved_to_floor else { return 0 }
            return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        }()
        
        return HStack(spacing: 16) {
            // Image
            ZStack {
                if let urlString = item.image_Url, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            RSMSTheme.Colors.backgroundElevated
                        }
                    }
                } else {
                    RSMSTheme.Colors.backgroundElevated
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                
                Text(item.sku)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(daysOnFloor) days")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.error)
                Text("on floor")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding(12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }
}
