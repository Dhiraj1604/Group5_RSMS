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
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            if products.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "cart.badge.minus")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                    Text("No sales recorded this month")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(products) { product in
                            soldProductRow(product)
                        }
                    }
                    .padding(20)
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
                            Color(UIColor.secondarySystemGroupedBackground)
                        }
                    }
                } else {
                    Color(UIColor.secondarySystemGroupedBackground)
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.primary)
                
                Text(product.displayQuantity)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.accentColor)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", product.totalRevenue))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.primary)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5))
    }
}

// MARK: - Fallback Items List

struct FallbackItemsListView: View {
    let items: [InventoryProduct]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            if items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.green.opacity(0.5))
                    Text("Fresh inventory! No fallback items.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(items) { item in
                            fallbackItemRow(item)
                        }
                    }
                    .padding(20)
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
                            Color(UIColor.secondarySystemGroupedBackground)
                        }
                    }
                } else {
                    Color(UIColor.secondarySystemGroupedBackground)
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.primary)
                
                Text(item.sku)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.accentColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(daysOnFloor) days")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.red)
                Text("on floor")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5))
    }
}
