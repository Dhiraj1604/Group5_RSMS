//
//  ProductsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Products tab placeholder.
//

//
//  ProductsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Products tab. SPRINT 1 STORY 4.
//  Story: "Set the official retail price for a product"
//  so it can be sold at a consistent value across every international boutique.
//
//  Uses Product from Core/Pricing/PricingModels.swift (base_price maps to Supabase `products` table).
//

import SwiftUI
import Supabase
import PostgREST

struct ProductsTab: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var searchText = ""
    @State private var filterUnpriced = false

    private var filteredProducts: [Product] {
        var list = products
        if filterUnpriced {
            list = list.filter { $0.basePrice == 0 }
        }
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.sku.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    private var unpricedCount: Int {
        products.filter { $0.basePrice == 0 }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if products.isEmpty {
                    emptyState
                } else {
                    productsList
                }
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search by name or SKU...")
            .task {
                await fetchProducts()
            }
            .refreshable {
                await fetchProducts()
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("Retry") { Task { await fetchProducts() } }
                Button("Dismiss", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error.")
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(RSMSTheme.Colors.accentGold)
            Text("Loading Products...")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    // MARK: - Products List

    private var productsList: some View {
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.md) {

                // Unpriced warning banner
                if unpricedCount > 0 {
                    unpricedBanner
                }

                // Filter chips
                filterChipsRow

                // Count label
                HStack {
                    Text("\(filteredProducts.count) product\(filteredProducts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, RSMSTheme.Spacing.xs)

                // Product cards
                if filteredProducts.isEmpty {
                    noResultsView
                } else {
                    ForEach(filteredProducts) { product in
                        NavigationLink(value: product) {
                            productCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer().frame(height: RSMSTheme.Spacing.xxl)
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.top, RSMSTheme.Spacing.md)
        }
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product, onPriceUpdated: {
                Task { await fetchProducts() }
            })
        }
    }

    // MARK: - Unpriced Banner

    private var unpricedBanner: some View {
        Button {
            withAnimation(.easeInOut) { filterUnpriced.toggle() }
        } label: {
            HStack(spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(RSMSTheme.Colors.warning)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unpricedCount) product\(unpricedCount == 1 ? "" : "s") without a price")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text("No transaction can happen without a price set")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }

                Spacer()

                Text(filterUnpriced ? "Show All" : "Filter")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.warning.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.warning.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Filter Chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                filterChip(label: "All", isSelected: !filterUnpriced) {
                    filterUnpriced = false
                }
                filterChip(label: "Unpriced", isSelected: filterUnpriced) {
                    filterUnpriced = true
                }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textSecondary)
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundDeep)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
        }
    }

    // MARK: - Product Card

    private func productCard(product: Product) -> some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .fill(product.basePrice > 0
                          ? RSMSTheme.Colors.accentGold.opacity(0.12)
                          : RSMSTheme.Colors.warning.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: "tag.fill")
                    .font(.title3)
                    .foregroundStyle(product.basePrice > 0
                                     ? RSMSTheme.Colors.accentGold
                                     : RSMSTheme.Colors.warning)
            }

            // Info
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(product.sku)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }

            Spacer()

            // Price badge
            VStack(alignment: .trailing, spacing: RSMSTheme.Spacing.xs) {
                if product.basePrice > 0 {
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                } else {
                    Text("Set Price")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, RSMSTheme.Spacing.md)
                        .padding(.vertical, RSMSTheme.Spacing.xs)
                        .background(RSMSTheme.Colors.warning)
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
        }
        .cardStyle()
    }

    // MARK: - Empty States

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

    private var noResultsView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text(filterUnpriced ? "All products are priced" : "No matching products")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .padding(.top, RSMSTheme.Spacing.xxxl)
    }

    // MARK: - Supabase Fetch

    @MainActor
    private func fetchProducts() async {
        isLoading = products.isEmpty
        errorMessage = nil
        do {
            let fetched: [Product] = try await SupabaseManager.shared.client
                .from("products")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.products = fetched
        } catch {
            print("❌ Failed to fetch products: \(error)")
            self.errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Product formatted price helper
extension Product {
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: basePrice)) ?? "$\(basePrice)"
    }
}

#Preview {
    ProductsTab()
}
