import SwiftUI
import Supabase
import PostgREST

struct ProductsTab: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory? = nil
    @State private var filterActive: Bool? = nil
    @State private var showAddProduct = false
    
    // 🛠️ CONFIGURATION
    private let supabaseURL = "https://bdgwzkpteyxhlgprlmye.supabase.co"
    private let bucketName = "product-images"
    
    // Amazon-style Grid Columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private var filteredProducts: [ProductNew] {
        var list = appState.products
        if let cat = selectedCategory { list = list.filter { $0.category == cat } }
        if let active = filterActive { list = list.filter { $0.isActive == active } }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.sku.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                if appState.isLoadingProducts && appState.products.isEmpty {
                    loadingView
                } else if appState.products.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: RSMSTheme.Spacing.md) {
                            categoryFilterRow
                            
                            // Amazon-style Grid
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(filteredProducts) { product in
                                    NavigationLink(value: product) {
                                        ShopProductCard(product: product, baseURL: supabaseURL, bucket: bucketName)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, RSMSTheme.Spacing.sm)
                        }
                        .padding(.horizontal, RSMSTheme.Spacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("RSMS Luxe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddProduct = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search products...")
            .task {
                if appState.products.isEmpty {
                    await appState.fetchProducts()
                }
            }
            .refreshable { await appState.fetchProducts() }
            .sheet(isPresented: $showAddProduct) { AddProductView() }
            .navigationDestination(for: ProductNew.self) { product in
                ProductDetailView(product: product)
            }
        }
    }
    
    // MARK: - Category Filter Row
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(label: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(ProductCategory.allCases) { cat in
                    filterChip(label: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textPrimary)
                .clipShape(Capsule())
        }
    }
    
    private var loadingView: some View {
        ProgressView().tint(RSMSTheme.Colors.accentGold)
    }
    
    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "tag.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.5))
            }
            VStack(spacing: RSMSTheme.Spacing.sm) {
                Text("No Products Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("Products from your Supabase `products` table\nwill appear here.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Amazon-Style Shop Card
    struct ShopProductCard: View {
        let product: ProductNew
        let baseURL: String
        let bucket: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // 1. Image View
                ZStack(alignment: .topTrailing) {
                    RSMSTheme.Colors.backgroundDeep
                    
                    if let path = product.imageUrl,
                       let url = URL(string: "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: product.category.icon).font(.largeTitle).opacity(0.2)
                            case .empty:
                                ProgressView().tint(RSMSTheme.Colors.accentGold)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Inactive Overlay
                    if !product.isActive {
                        Text("OUT OF STOCK")
                            .font(.system(size: 8, weight: .bold))
                            .padding(4)
                            .background(.black.opacity(0.7))
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                            .padding(8)
                    }
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .clipped()
                
                // 2. Details
                VStack(alignment: .leading, spacing: 2) {
                    Text("RSMS LUXE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    
                    Text(product.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 2) {
                        Text("₹")
                            .font(.system(size: 12, weight: .bold))
                        Text(product.basePrice > 0 ? String(format: "%.0f", product.basePrice) : "Price on Request")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .padding(.top, 2)
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
