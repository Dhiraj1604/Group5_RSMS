import SwiftUI

struct ProductListView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddProduct = false
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    
    // Luxurious Grid Definition
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // Filter logic based on search and category chips
    private var filteredProducts: [Product] {
        appState.products.filter { product in
            let matchesSearch = searchText.isEmpty || product.name.lowercased().contains(searchText.lowercased())
            let matchesCat = selectedCategory == "All" || product.category.rawValue == selectedCategory
            return matchesSearch && matchesCat
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // 1. Luxury Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    TextField("Search products...", text: $searchText)
                        .font(.custom("Helvetica", size: 15))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(RSMSTheme.Radius.pill)
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.vertical, RSMSTheme.Spacing.md)

                // 2. Category Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CategoryChip(title: "All", isSelected: selectedCategory == "All") {
                            selectedCategory = "All"
                        }
                        // Replace with your actual Product Category enum cases
                        ForEach(["Handbags", "Footwear", "Accessories", "Fragrances"], id: \.self) { cat in
                            CategoryChip(title: cat, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.bottom, RSMSTheme.Spacing.md)
                }

                // 3. Content Area
                ZStack {
                    RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                    
                    if appState.isLoadingProducts && appState.products.isEmpty {
                        loadingView
                    } else if filteredProducts.isEmpty {
                        emptyCatalogView
                    } else {
                        productGrid
                    }
                }
            }
            .navigationTitle("RSMS Catalogue")
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
            .task {
                await appState.fetchProducts()
            }
            .sheet(isPresented: $showAddProduct) {
                AddProductView()
            }
        }
    }

    private var productGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filteredProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        ProductShopCard(product: product)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.top, RSMSTheme.Spacing.sm)
        }
        .refreshable {
            await appState.fetchProducts()
        }
    }

    // MARK: - RSMS Shop Card
    struct ProductShopCard: View {
        let product: Product
        
        // 🛠️ CONFIGURATION: Replace these with your project details
        private let supabaseProjectID = "https://bdgwzkpteyxhlgprlmye.supabase.co"
        private let bucketName = "product-images"
        
        // Computed property to build the full URL
        private var publicImageUrl: URL? {
            guard let path = product.imageUrl else { return nil }
            
            // If the path is already a full URL, use it directly
            if path.hasPrefix("http") {
                return URL(string: path)
            } else {
                let urlString = "\(supabaseProjectID)/storage/v1/object/public/\(bucketName)/\(path)"
                return URL(string: urlString)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Image Container
                ZStack {
                    RSMSTheme.Colors.backgroundDeep
                    
                    if let url = publicImageUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .transition(.opacity)
                            case .failure:
                                // Fallback to category icon if image fails to load
                                placeholderIcon
                            case .empty:
                                ProgressView()
                                    .tint(RSMSTheme.Colors.accentGold)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        placeholderIcon
                    }
                    
                    // Category Badge (Top Right)
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: product.category.icon)
                                .font(.caption2)
                                .foregroundStyle(.black)
                                .padding(6)
                                .background(RSMSTheme.Colors.accentGold)
                                .clipShape(Circle())
                                .padding(RSMSTheme.Spacing.xs)
                        }
                        Spacer()
                    }
                }
                .frame(height: 180) // Fixed height for grid stability
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                .clipped()
                
                // 2. Info Container
                VStack(alignment: .leading, spacing: 4) {
                    // Brand Label (Luxury Aesthetic)
                    Text("RSMS LUXE")
                        .font(.custom("Helvetica", size: 10).weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .textCase(.uppercase)
                    
                    Text(product.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text(product.sku)
                        .font(.system(size: 10))
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("₹")
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%.0f", product.basePrice))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .padding(.top, 2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
        }
        
        // Helper for placeholder
        private var placeholderIcon: some View {
            Image(systemName: product.category.icon)
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.3))
        }
    }

    // MARK: - Helper Views
    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView().tint(RSMSTheme.Colors.accentGold)
            Text("Refreshing Collection...").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    private var emptyCatalogView: some View {
        ContentUnavailableView {
            Label("No Matches", systemImage: "magnifyingglass")
                .foregroundStyle(RSMSTheme.Colors.accentGold)
        } description: {
            Text("Try adjusting your search or filters.")
        }
    }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Helvetica", size: 14).weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : RSMSTheme.Colors.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
