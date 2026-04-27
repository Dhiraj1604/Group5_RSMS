import SwiftUI

enum ReportMode {
    case sold
    case slowMoving
}

struct ProductSalesReportView: View {
    let soldProducts: [SoldProduct]
    let unsoldProducts: [InventoryProduct]
    let mode: ReportMode
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    if mode == .sold {
                        if soldProducts.isEmpty {
                            EmptyStateView(title: "No recent sales", message: "No products sold within the last 30 days.")
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(soldProducts) { product in
                                    SoldProductCard(product: product)
                                }
                            }
                            .padding()
                        }
                    } else {
                        if unsoldProducts.isEmpty {
                            EmptyStateView(title: "No slow items", message: "No products have been in stock for more than 30 days.")
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(unsoldProducts) { product in
                                    UnsoldProductCard(product: product)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationTitle(mode == .sold ? "Recent Sales" : "Slow Moving")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SoldProductCard: View {
    let product: SoldProduct
    
    var body: some View {
        HStack(spacing: 16) {
            ProductImage(url: product.imageUrl)
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(RSMSTheme.Typography.bodyCopy1)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                
                Text(product.sku)
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                
                Spacer()
                
                HStack {
                    Label("\(product.quantitySold) sold", systemImage: "bag.fill")
                        .font(RSMSTheme.Typography.caption)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("₹\(Int(product.totalRevenue))")
                        .font(RSMSTheme.Typography.bodyCopy1)
                        .foregroundColor(RSMSTheme.Colors.success)
                }
            }
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}

struct UnsoldProductCard: View {
    let product: InventoryProduct
    
    var body: some View {
        HStack(spacing: 16) {
            ProductImage(url: product.image_Url)
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(RSMSTheme.Typography.bodyCopy1)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                
                Text(product.sku)
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                
                Spacer()
                
                HStack {
                    Text("In stock")
                        .font(RSMSTheme.Typography.caption)
                        .foregroundColor(RSMSTheme.Colors.warning)
                    
                    if let lastMoved = product.last_moved_to_floor {
                        let days = Calendar.current.dateComponents([.day], from: lastMoved, to: Date()).day ?? 0
                        Text("• \(days) days")
                            .font(RSMSTheme.Typography.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(RSMSTheme.Colors.textTertiary)
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}

struct ProductImage: View {
    let url: String?
    
    var body: some View {
        if let urlString = url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.1)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                }
            }
        } else {
            Color.gray.opacity(0.1)
                .overlay(Image(systemName: "photo").foregroundColor(.gray))
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 100)
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(RSMSTheme.Colors.textTertiary)
            Text(title)
                .font(RSMSTheme.Typography.heading4)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Text(message)
                .font(RSMSTheme.Typography.caption)
                .foregroundColor(RSMSTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
