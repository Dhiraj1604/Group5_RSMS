import SwiftUI
import Supabase

struct ProductDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let product: Product
    var onPriceUpdated: (() -> Void)? = nil

    // 🛠️ CONFIGURATION
    private let supabaseURL = "https://bdgwzkpteyxhlgprlmye.supabase.co"
    private let bucketName = "product-images"

    // MARK: - State
    @State private var isEditing: Bool = false
    @State private var showSetPrice: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var updateError: String? = nil

    // MARK: - Editable Fields
    @State private var sku: String = ""
    @State private var selectedCategory: ProductCategory = .other
    @State private var material: String = ""
    @State private var originCountry: String = ""
    @State private var selectedCraftsmanship: CraftsmanshipLevel = .handcrafted
    @State private var craftsmanshipNotes: String = ""
    @State private var collectionName: String = ""
    @State private var artisanStudio: String = ""
    @State private var isGloballyListed: Bool = true

    private var currentProduct: Product {
        appState.products.first(where: { $0.id == product.id }) ?? product
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                HStack(alignment: .top, spacing: RSMSTheme.Spacing.xl) {
                    // ── LEFT COLUMN: Image + Name + SKU + Price ──
                    leftColumn
                        .frame(width: 320)
                        .frame(maxHeight: .infinity, alignment: .top)

                    // ── RIGHT COLUMN: All detail sections ──
                    rightColumn
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
                .padding(.bottom, RSMSTheme.Spacing.xxl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button { cancelEditing() } label: {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { saveProduct() } label: {
                        Image(systemName: "checkmark").font(.body.weight(.semibold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startEditing() } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
        .sheet(isPresented: $showSetPrice, onDismiss: { onPriceUpdated?() }) {
            SetPriceView(product: currentProduct)
        }
        .alert("Update Failed", isPresented: Binding<Bool>(
            get: { updateError != nil },
            set: { if !$0 { updateError = nil } }
        )) {
            Button("OK") { }
        } message: {
            Text(updateError ?? "Unknown error")
        }
        .onAppear { populateFields() }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - LEFT COLUMN
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.lg) {
            // Product Image
            productImage

            // Product Name
            Text(currentProduct.name)
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // SKU + Category
            HStack(spacing: RSMSTheme.Spacing.sm) {
                TextField("SKU", text: $sku)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .textInputAutocapitalization(.characters)
                    .disabled(!isEditing)

                Text("·")
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)

                if isEditing {
                    Picker("", selection: $selectedCategory) {
                        ForEach(ProductCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.Colors.textSecondary)
                } else {
                    Text(currentProduct.category.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }

            Divider().background(RSMSTheme.Colors.borderLight)

            // Price
            priceBlock

            Spacer(minLength: RSMSTheme.Spacing.sm)

            // Action buttons
            actionButtons
        }
    }

    private var productImage: some View {
        ZStack {
            RSMSTheme.Colors.backgroundDeep

            if let path = currentProduct.imageUrl,
               let url = path.hasPrefix("http")
                   ? URL(string: path)
                   : URL(string: "\(supabaseURL)/storage/v1/object/public/\(bucketName)/\(path)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(width: 320, height: 320)
                            .clipped()
                    case .failure:
                        categoryPlaceholder
                            .frame(width: 320, height: 320)
                    case .empty:
                        ProgressView().tint(RSMSTheme.Colors.accentGold)
                            .frame(width: 320, height: 320)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                categoryPlaceholder
                    .frame(width: 320, height: 320)
            }
        }
        .frame(width: 320, height: 320)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }

    private var categoryPlaceholder: some View {
        ZStack {
            RSMSTheme.Colors.backgroundDeep
            Image(systemName: currentProduct.category.icon)
                .font(.system(size: 60))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.2))
        }
    }

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
            Text("RETAIL PRICE")
                .font(.caption2).fontWeight(.bold)
                .foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)

            if currentProduct.basePrice > 0 {
                HStack {
                    Text(currentProduct.formattedPrice)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)

                    Spacer()

                    Button { showSetPrice = true } label: {
                        Image(systemName: "pencil")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .padding(8)
                            .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            } else {
                Button { showSetPrice = true } label: {
                    HStack(spacing: RSMSTheme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(RSMSTheme.Colors.warning)
                        Text("Set Price")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - RIGHT COLUMN
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private var rightColumn: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            statusCard
            craftsmanshipCard
            heritageCard
        }
    }

    // MARK: - Status Card
    private var statusCard: some View {
        detailSection(title: "Visibility & Status") {
            staticRow(icon: "checkmark.circle.fill", label: "Active Status",
                      value: currentProduct.isActive ? "Active" : "Inactive",
                      valueColor: currentProduct.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
            Divider().background(RSMSTheme.Colors.borderLight)

            HStack(spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "globe").font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7)).frame(width: 24)
                Text("Global Listing").font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                if isEditing {
                    Toggle("", isOn: $isGloballyListed)
                        .tint(RSMSTheme.Colors.accentGold)
                        .labelsHidden()
                } else {
                    Text(currentProduct.isGloballyListed ? "Listed on all boutiques" : "Unlisted")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(currentProduct.isGloballyListed ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.warning)
                }
            }
            .padding(.vertical, RSMSTheme.Spacing.md)
        }
    }

    // MARK: - Craftsmanship Card
    private var craftsmanshipCard: some View {
        detailSection(title: "Materials & Craftsmanship") {
            editableRow(icon: "atom", label: "Materials", text: $material)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "globe.europe.africa", label: "Country of Origin", text: $originCountry)
            Divider().background(RSMSTheme.Colors.borderLight)

            HStack(spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "star.fill").font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7)).frame(width: 24)
                Text("Craftsmanship").font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                if isEditing {
                    Picker("", selection: $selectedCraftsmanship) {
                        ForEach(CraftsmanshipLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.Colors.accentGold)
                } else {
                    Text(currentProduct.craftsmanshipLevel.rawValue)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
            }
            .padding(.vertical, RSMSTheme.Spacing.md)

            Divider().background(RSMSTheme.Colors.borderLight)

            // Artisan Notes
            HStack(alignment: .top, spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "text.quote").font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7)).frame(width: 24)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                    Text("Artisan Notes")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary).textCase(.uppercase)
                    TextField("Artisan notes", text: $craftsmanshipNotes, axis: .vertical)
                        .font(.subheadline).foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1...5)
                        .disabled(!isEditing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, RSMSTheme.Spacing.sm)
        }
    }

    // MARK: - Heritage Card
    private var heritageCard: some View {
        detailSection(title: "Heritage & Provenance") {
            editableRow(icon: "crown.fill", label: "Collection", text: $collectionName)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "paintpalette.fill", label: "Artisan Studio", text: $artisanStudio)
            Divider().background(RSMSTheme.Colors.borderLight)
            staticRow(icon: "calendar", label: "Added",
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
                    Task { dismiss(); await appState.deleteProduct(currentProduct) }
                }
            } message: {
                Text("This cannot be undone. The product will be permanently removed.")
            }
        }
        .padding(.top, RSMSTheme.Spacing.sm)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Reusable Components
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

    private func editableRow(icon: String, label: String, text: Binding<String>,
                             keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon).font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7)).frame(width: 24)
            Text(label).font(.subheadline).foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            TextField("—", text: text)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .disabled(!isEditing)
        }
        .padding(.vertical, RSMSTheme.Spacing.md)
    }

    private func staticRow(icon: String, label: String, value: String,
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

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - Editing Actions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private func populateFields() {
        sku = currentProduct.sku
        selectedCategory = currentProduct.category
        material = currentProduct.material
        originCountry = currentProduct.originCountry
        selectedCraftsmanship = currentProduct.craftsmanshipLevel
        craftsmanshipNotes = currentProduct.craftsmanshipNotes
        collectionName = currentProduct.collectionName
        artisanStudio = currentProduct.artisanStudio
        isGloballyListed = currentProduct.isGloballyListed
    }

    private func startEditing() {
        populateFields()
        isEditing = true
    }

    private func cancelEditing() {
        populateFields()
        isEditing = false
    }

    private func saveProduct() {
        let productToSave = Product(
            id: currentProduct.id,
            sku: sku.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            name: currentProduct.name,
            imageUrl: currentProduct.imageUrl,
            category: selectedCategory,
            isActive: currentProduct.isActive,
            isGloballyListed: isGloballyListed,
            createdAt: currentProduct.createdAt,
            updatedAt: Date(),
            basePrice: currentProduct.basePrice,
            material: material.trimmingCharacters(in: .whitespacesAndNewlines),
            originCountry: originCountry.trimmingCharacters(in: .whitespacesAndNewlines),
            craftsmanshipLevel: selectedCraftsmanship,
            craftsmanshipNotes: craftsmanshipNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            collectionName: collectionName.trimmingCharacters(in: .whitespacesAndNewlines),
            artisanStudio: artisanStudio.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        Task {
            await appState.updateProduct(productToSave)
            if appState.productError == nil {
                isEditing = false
            } else {
                updateError = appState.productError
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(product: Product.sample)
    }
    .environment(AppState())
}
