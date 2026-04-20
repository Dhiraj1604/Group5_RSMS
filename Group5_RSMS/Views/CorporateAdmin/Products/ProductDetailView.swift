import SwiftUI
import Supabase

struct ProductDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let product: ProductNew
    var onPriceUpdated: (() -> Void)? = nil

    // 🛠️ CONFIGURATION
    private let supabaseURL = "https://bdgwzkpteyxhlgprlmye.supabase.co"
    private let bucketName = "product-images"

    // MARK: - State
    @State private var showSetPrice: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var updateError: String? = nil

    // Always read the live version from AppState so UI reflects updates
    private var currentProduct: ProductNew {
        appState.products.first(where: { $0.id == product.id }) ?? product
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    productHeroImage
                    productInfoCard
                    activeStatusSection
                    priceSection
                    statusCard
                    craftsmanshipCard
                    heritageCard
                    actionButtons
                    Spacer().frame(height: RSMSTheme.Spacing.xxl)
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
            }
        }
        .navigationTitle(currentProduct.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditSheet = true } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showSetPrice, onDismiss: {
            onPriceUpdated?()
        }) {
            SetPriceView(product: currentProduct)
        }
        .sheet(isPresented: $showEditSheet) {
            AddProductView(existingProduct: currentProduct)
        }
        .alert("Update Failed", isPresented: Binding<Bool>(
            get: { updateError != nil },
            set: { if !$0 { updateError = nil } }
        )) {
            Button("OK") { }
        } message: {
            Text(updateError ?? "Unknown error")
        }
    }

    // MARK: - Hero Image
    private var productHeroImage: some View {
        ZStack {
            RSMSTheme.Colors.backgroundDeep

            if let path = currentProduct.imageUrl,
               let detailURL = URL(string: "\(supabaseURL)/storage/v1/object/public/\(bucketName)/\(path)") {
                AsyncImage(url: detailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        categoryPlaceholder
                    case .empty:
                        ProgressView().tint(RSMSTheme.Colors.accentGold)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                categoryPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 350)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        .clipped()
    }

    private var categoryPlaceholder: some View {
        Image(systemName: currentProduct.category.icon)
            .font(.system(size: 60))
            .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.2))
    }

    // MARK: - Product Info Card
    private var productInfoCard: some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: currentProduct.category.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(currentProduct.name)
                    .font(.title3).fontWeight(.bold).foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(currentProduct.sku)
                    .font(.subheadline).foregroundStyle(RSMSTheme.Colors.accentGold)
                Text(currentProduct.category.rawValue)
                    .font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }

    // MARK: - Active Status Section
    private var activeStatusSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Label("Global Visibility", systemImage: "globe")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Status")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text(currentProduct.isActive ? "Available across all boutiques" : "Hidden from staff and customers")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { currentProduct.isActive },
                    set: { newValue in
                        Task { await updateActiveStatus(newState: newValue) }
                    }
                ))
                .labelsHidden()
                .tint(RSMSTheme.Colors.accentGold)
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(currentProduct.isActive ? RSMSTheme.Colors.borderLight : RSMSTheme.Colors.warning.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Price Section
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Label("Official Retail Price", systemImage: "indianrupeesign.circle.fill")
                .font(.headline).foregroundStyle(RSMSTheme.Colors.textPrimary)

            if currentProduct.basePrice > 0 {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                        Text("CURRENT PRICE")
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary).textCase(.uppercase)
                        Text(currentProduct.formattedPrice)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                    Spacer()
                    Button { showSetPrice = true } label: {
                        Label("Update", systemImage: "pencil")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .padding(.horizontal, RSMSTheme.Spacing.lg)
                            .padding(.vertical, RSMSTheme.Spacing.md)
                            .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(RSMSTheme.Colors.accentGold.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(RSMSTheme.Spacing.xl)
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.accentGold.opacity(0.25), lineWidth: 1))
            } else {
                VStack(spacing: RSMSTheme.Spacing.lg) {
                    HStack(spacing: RSMSTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RSMSTheme.Colors.warning).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Price Set").font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Text("This product cannot be sold until a retail price is set.")
                                .font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    Button { showSetPrice = true } label: {
                        Label("Set Retail Price", systemImage: "indianrupeesign.circle")
                    }
                    .buttonStyle(GoldButtonStyle())
                }
                .padding(RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.warning.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.warning.opacity(0.25), lineWidth: 1))
            }
        }
    }

    // MARK: - Status Card
    private var statusCard: some View {
        detailSection(title: "Visibility & Status") {
            infoRow(icon: "checkmark.circle.fill", label: "Active Status",
                    value: currentProduct.isActive ? "Active" : "Inactive",
                    valueColor: currentProduct.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
            Divider().background(RSMSTheme.Colors.borderLight)
            infoRow(icon: "globe", label: "Global Listing",
                    value: currentProduct.isGloballyListed ? "Listed on all boutiques" : "Unlisted",
                    valueColor: currentProduct.isGloballyListed ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.warning)
        }
    }

    // MARK: - Craftsmanship Card
    private var craftsmanshipCard: some View {
        detailSection(title: "Materials & Craftsmanship") {
            if !currentProduct.material.isEmpty {
                infoRow(icon: "atom", label: "Materials", value: currentProduct.material)
                Divider().background(RSMSTheme.Colors.borderLight)
            }
            if !currentProduct.originCountry.isEmpty {
                infoRow(icon: "globe.europe.africa", label: "Country of Origin", value: currentProduct.originCountry)
                Divider().background(RSMSTheme.Colors.borderLight)
            }
            infoRow(icon: "star.fill", label: "Craftsmanship", value: currentProduct.craftsmanshipLevel.rawValue)
            if !currentProduct.craftsmanshipNotes.isEmpty {
                Divider().background(RSMSTheme.Colors.borderLight)
                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                    Label("Artisan Notes", systemImage: "text.quote")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary).textCase(.uppercase)
                    Text(currentProduct.craftsmanshipNotes)
                        .font(.subheadline).foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, RSMSTheme.Spacing.sm)
            }
        }
    }

    // MARK: - Heritage Card
    private var heritageCard: some View {
        detailSection(title: "Heritage & Provenance") {
            if !currentProduct.collectionName.isEmpty {
                infoRow(icon: "crown.fill", label: "Collection", value: currentProduct.collectionName)
                Divider().background(RSMSTheme.Colors.borderLight)
            }
            if !currentProduct.artisanStudio.isEmpty {
                infoRow(icon: "paintpalette.fill", label: "Artisan Studio", value: currentProduct.artisanStudio)
                Divider().background(RSMSTheme.Colors.borderLight)
            }
            infoRow(icon: "calendar", label: "Added",
                    value: currentProduct.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            Button {
                Task { await appState.toggleProductActive(currentProduct) }
            } label: {
                HStack {
                    Image(systemName: currentProduct.isActive ? "pause.circle.fill" : "play.circle.fill")
                    Text(currentProduct.isActive ? "Deactivate Product" : "Activate Product")
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button { showDeleteConfirm = true } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Product")
                }
                .font(.headline).fontWeight(.medium)
                .foregroundStyle(RSMSTheme.Colors.error)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RSMSTheme.Colors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1))
            }
            .confirmationDialog("Delete \(currentProduct.name)?",
                                isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        await appState.deleteProduct(currentProduct)
                        dismiss()
                    }
                }
            } message: {
                Text("This cannot be undone. The product will be permanently removed.")
            }
        }
        .padding(.top, RSMSTheme.Spacing.sm)
    }

    // MARK: - Reusable Components
    private func detailSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Rectangle().fill(RSMSTheme.Colors.accentGold).frame(width: 3, height: 16).clipShape(Capsule())
                Text(title).font(.headline).fontWeight(.semibold).foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
            VStack(spacing: 0) { content() }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    private func infoRow(icon: String, label: String, value: String,
                         valueColor: Color = RSMSTheme.Colors.textPrimary) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon).font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7)).frame(width: 24)
            Text(label).font(.subheadline).foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium)
                .foregroundStyle(valueColor).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, RSMSTheme.Spacing.md)
    }

    // MARK: - Active Status Update
    // Uses AppState so the computed currentProduct auto-refreshes via @Observable
    @MainActor
    private func updateActiveStatus(newState: Bool) async {
        do {
            try await SupabaseManager.shared.client
                .from("products")
                .update(["is_active": newState])
                .eq("id", value: currentProduct.id)
                .execute()

            print("✅ Active status updated")

            // Audit log
            ActivityLogService.shared.log(
                userEmail: appState.userEmail,
                action: newState ? .activated : .deactivated,
                entity: .product,
                entityName: currentProduct.name,
                entityId: currentProduct.id.uuidString,
                details: "Product \(newState ? "activated" : "deactivated")"
            )

            // Refresh AppState so currentProduct computed var picks up new value
            await appState.fetchProducts()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onPriceUpdated?()
            }
        } catch {
            print("❌ Failed to update active status: \(error)")
            updateError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: ProductNew.sample)
    }
    .environment(AppState())
}
