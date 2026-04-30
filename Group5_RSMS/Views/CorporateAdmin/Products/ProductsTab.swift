import SwiftUI
import Supabase
import PostgREST

struct ProductsTab: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCategories: Set<ProductCategory> = []   // empty = All
    @State private var filterActive: Bool? = nil
    @State private var showAddProduct = false
    @State private var showingProfile = false
    
    // 🛠️ CONFIGURATION
    private let supabaseURL = "https://bdgwzkpteyxhlgprlmye.supabase.co"
    private let bucketName = "product-images"
    
    // Amazon-style Grid Columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private var filteredProducts: [Product] {
        var list = appState.products
        if !selectedCategories.isEmpty { list = list.filter { selectedCategories.contains($0.category) } }
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
                            
                            // Cinematic Square Boutique Grid
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20)], spacing: 24) {
                                ForEach(filteredProducts) { product in
                                    NavigationLink(value: product) {
                                        BoutiqueSquareProductCard(product: product, baseURL: supabaseURL, bucket: bucketName)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, RSMSTheme.Spacing.sm)
                        }
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showAddProduct = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("Add Product")
                        
                        Button {
                            showingProfile = true
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("My Profile")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search products...")
            .task {
                await appState.fetchProducts()
            }
            .refreshable { await appState.fetchProducts() }
            .sheet(isPresented: $showAddProduct) { AddProductView() }
            .sheet(isPresented: $showingProfile) {
                AdminProfileView()
                    .presentationDetents([.large])
            }
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
            .alert("Product Update", isPresented: Binding<Bool>(
                get: { appState.productError != nil },
                set: { if !$0 { appState.productError = nil } }
            )) {
                Button("OK") { }
            } message: {
                Text(appState.productError ?? "Unknown error")
            }
        }
    }
    
    // MARK: - Category Filter Row (multi-select)
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" pill — clears selection
                filterChip(label: "All", isSelected: selectedCategories.isEmpty) {
                    selectedCategories.removeAll()
                }
                ForEach(ProductCategory.allCases) { cat in
                    filterChip(label: cat.rawValue, isSelected: selectedCategories.contains(cat)) {
                        if selectedCategories.contains(cat) {
                            selectedCategories.remove(cat)
                        } else {
                            selectedCategories.insert(cat)
                        }
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
    
    // MARK: - Cinematic Boutique Product Tile
    struct BoutiqueSquareProductCard: View {
        let product: Product
        let baseURL: String
        let bucket: String
        
        private var imageURL: URL? {
            guard let path = product.imageUrl else { return nil }
            if path.hasPrefix("http") {
                return URL(string: path)
            } else {
                return URL(string: "\(baseURL)/storage/v1/object/public/\(bucket)/\(path)")
            }
        }
        
        var body: some View {
            ZStack(alignment: .bottomLeading) {
                // 1. Full-Bleed Background Image (Fixed Height, Flexible Width)
                ZStack {
                    if let url = imageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()
                            case .empty, .failure:
                                RSMSTheme.Colors.backgroundDeep
                                    .overlay(
                                        ProgressView()
                                            .tint(RSMSTheme.Colors.accentGold.opacity(0.3))
                                    )
                            @unknown default:
                                RSMSTheme.Colors.backgroundDeep
                            }
                        }
                    } else {
                        RSMSTheme.Colors.backgroundDeep
                    }
                }
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .clipped()
                
                // 2. Luxurious Overlays
                ZStack {
                    // Overall dark atmospheric overlay
                    Color.black.opacity(0.5)
                    
                    // The Signature Golden floor-glow
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [RSMSTheme.Colors.accentGold.opacity(0.4), .clear],
                            startPoint: .bottom,
                            endPoint: .center
                        )
                        .frame(height: 120)
                    }
                    
                    // 'Guilloché' Dot Matrix Texture
                    Canvas { context, size in
                        let spacing: CGFloat = 12
                        let dotSize: CGFloat = 1.0
                        for y in stride(from: spacing/2, through: size.height, by: spacing) {
                            for x in stride(from: spacing/2, through: size.width, by: spacing) {
                                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.15)))
                            }
                        }
                    }
                    .blendMode(.plusLighter)
                }
                
                // 3. Editorial Typography Layout
                // Use a single overlay for all text to ensure consistent coordinate space
                VStack(spacing: 0) {
                    // Top Row: Category & Name
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.category.rawValue.uppercased())
                                .font(.custom("HelveticaNeue-Bold", size: 10))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .tracking(2)
                                .shadow(color: .black.opacity(0.8), radius: 2)
                            
                            Text(product.name)
                                .font(.custom("HelveticaNeue-Bold", size: 22))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .shadow(color: .black.opacity(0.8), radius: 4)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Bottom Row: Price Hero
                    HStack(alignment: .bottom) {
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("₹")
                                .font(.custom("HelveticaNeue", size: 16))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                            
                            Text(product.basePrice > 0 ? (Self.indianFormatter.string(from: NSNumber(value: product.basePrice)) ?? "0") : "On Request")
                                .font(.custom("HelveticaNeue-Bold", size: 28))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .shadow(color: .black.opacity(0.8), radius: 3)
                    }
                }
                .padding(24) // Luxury padding
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), .clear, RSMSTheme.Colors.accentGold.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
        }
        
        private static let indianFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "en_IN")
            return formatter
        }()
        
        private var imagePlaceholder: some View {
            VStack(spacing: 12) {
                Image(systemName: product.category.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.25))
                Text(product.category.rawValue.uppercased())
                    .font(.custom("HelveticaNeue-Bold", size: 9))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .tracking(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
