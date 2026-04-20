//
//  AddProductView.swift
//  Group5_RSMS
//
//  Sprint 1 — Task #2 (Product & Pricing Engine)
//            Task #5 (Material, Origin & Craftsmanship Details)
//            Task #Image (Camera/Gallery Uploads)
//
//  Saves to Supabase `products` table via AppState.addProduct() / updateProduct()
//  Uploads images to Supabase Storage bucket 'product-images'
//

import SwiftUI
import Supabase

struct AddProductView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var existingProduct: Product? = nil

    // Core
    @State private var sku: String = ""
    @State private var name: String = ""
    @State private var selectedCategory: ProductCategory = .other
    @State private var basePriceInput: String = ""
    @State private var isActive: Bool = true
    @State private var isGloballyListed: Bool = true
    
    // IMAGE STATE
    @State private var selectedUIImage: UIImage? = nil
    @State private var existingImageUrl: String? = nil
    @State private var showImageSourceDialog = false
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingImage = false

    // Task #5 — Craftsmanship
    @State private var material: String = ""
    @State private var originCountry: String = ""
    @State private var selectedCraftsmanship: CraftsmanshipLevel = .handcrafted
    @State private var craftsmanshipNotes: String = ""
    @State private var collectionName: String = ""
    @State private var artisanStudio: String = ""

    // UI State
    @State private var showValidationErrors: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    private var isEditing: Bool { existingProduct != nil }

    private var isFormValid: Bool {
        !sku.trimmed.isEmpty &&
        !name.trimmed.isEmpty &&
        !material.trimmed.isEmpty &&
        !originCountry.trimmed.isEmpty &&
        !collectionName.trimmed.isEmpty &&
        !artisanStudio.trimmed.isEmpty &&
        (Double(basePriceInput) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        
                        imageUploaderHeader
                        
                        coreInfoSection
                        pricingSection
                        statusSection
                        craftsmanshipSection
                        heritageSection
                        
                        saveButton
                        
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Edit Product" : "New Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .disabled(isLoading || isUploadingImage)
                }
            }
            .confirmationDialog("Product Image", isPresented: $showImageSourceDialog) {
                Button("Take Photo (Camera)") {
                    imageSource = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    imageSource = .photoLibrary
                    showImagePicker = true
                }
                if isEditing && (existingImageUrl != nil || selectedUIImage != nil) {
                    Button("Remove Image", role: .destructive) {
                        selectedUIImage = nil
                        existingImageUrl = nil
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedUIImage, sourceType: imageSource)
                    .ignoresSafeArea()
            }
            .alert(isEditing ? "Product Updated ✓" : "Product Added! ✓", isPresented: $showSuccessAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(name) has been successfully \(isEditing ? "updated" : "added to the catalogue").")
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred.")
            }
            .onAppear { populateIfEditing() }
        }
    }

    // MARK: - Image Uploader Header

    private var imageUploaderHeader: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            Button {
                showImageSourceDialog = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .fill(RSMSTheme.Colors.backgroundDeep)
                        .frame(width: 140, height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                        )

                    if let newImage = selectedUIImage {
                        Image(uiImage: newImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                    } else if let urlString = existingImageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView().tint(RSMSTheme.Colors.accentGold)
                        }
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                    } else {
                        VStack(spacing: RSMSTheme.Spacing.sm) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                            Text(isEditing ? "Change Image" : "Add Image")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                    }
                    
                    if isUploadingImage {
                        Color.black.opacity(0.6)
                            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                        ProgressView().tint(.white)
                    }
                }
            }
            .disabled(isLoading || isUploadingImage)

            Text(isEditing ? "Edit product details" : "Add a new product to the catalogue")
                .font(.subheadline).foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }

    // MARK: - Sections

    private var coreInfoSection: some View {
        formSection(title: "Product Information") {
            formField(label: "SKU", placeholder: "e.g. JWL-RNG-001", text: $sku, icon: "barcode", required: true)
                .textInputAutocapitalization(.characters)
            formField(label: "Product Name", placeholder: "e.g. Maharaja Diamond Ring", text: $name, icon: "tag", required: true)
            categoryPicker
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
            fieldLabel("Category", required: true)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(ProductCategory.allCases) { cat in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { selectedCategory = cat }
                        } label: {
                            HStack(spacing: RSMSTheme.Spacing.xs) {
                                Image(systemName: cat.icon).font(.caption)
                                Text(cat.rawValue).font(.caption).fontWeight(.medium)
                            }
                            .foregroundStyle(selectedCategory == cat ? .black : RSMSTheme.Colors.textSecondary)
                            .padding(.horizontal, RSMSTheme.Spacing.md)
                            .padding(.vertical, RSMSTheme.Spacing.sm)
                            .background(selectedCategory == cat ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedCategory == cat ? Color.clear : RSMSTheme.Colors.border, lineWidth: 1))
                        }
                    }
                }
            }
        }
    }

    private var pricingSection: some View {
        formSection(title: "Pricing") {
            formField(label: "Retail Price (₹ INR)", placeholder: "e.g. 485000", text: $basePriceInput, icon: "indianrupeesign.circle", required: true)
                .keyboardType(.decimalPad)
        }
    }

    private var statusSection: some View {
        formSection(title: "Visibility & Status") {
            toggleRow(icon: "checkmark.circle.fill", label: "Active", sublabel: "POS only shows active products", isOn: $isActive, color: RSMSTheme.Colors.success)
            Divider().background(RSMSTheme.Colors.borderLight)
            toggleRow(icon: "globe", label: "Globally Listed", sublabel: "Visible across all boutiques", isOn: $isGloballyListed, color: RSMSTheme.Colors.accentGold)
        }
    }

    private var craftsmanshipSection: some View {
        formSection(title: "Materials & Craftsmanship") {
            formField(label: "Materials", placeholder: "e.g. 18K Yellow Gold", text: $material, icon: "atom", required: true)
            formField(label: "Country of Origin", placeholder: "e.g. India", text: $originCountry, icon: "globe.europe.africa", required: true)
            craftsmanshipPicker
            notesField(label: "Craftsmanship Notes", placeholder: "Artisan techniques...", text: $craftsmanshipNotes)
        }
    }
    
    private var craftsmanshipPicker: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
            fieldLabel("Craftsmanship Level", required: false)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(CraftsmanshipLevel.allCases, id: \.self) { level in
                        Button { selectedCraftsmanship = level } label: {
                            Text(level.rawValue)
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(selectedCraftsmanship == level ? .black : RSMSTheme.Colors.textSecondary)
                                .padding(.horizontal, RSMSTheme.Spacing.md)
                                .padding(.vertical, RSMSTheme.Spacing.sm)
                                .background(selectedCraftsmanship == level ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var heritageSection: some View {
        formSection(title: "Heritage & Provenance") {
            formField(label: "Collection Name", placeholder: "Collection Name", text: $collectionName, icon: "crown.fill", required: true)
            formField(label: "Artisan Studio", placeholder: "Atelier location", text: $artisanStudio, icon: "paintpalette.fill", required: true)
        }
    }

    private var saveButton: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            if showValidationErrors && !isFormValid {
                Text("Please fill in all required fields.").font(.caption).foregroundStyle(RSMSTheme.Colors.error)
            }
            Button { saveProduct() } label: {
                HStack {
                    if isLoading || isUploadingImage { ProgressView().tint(.black) }
                    else { Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill") }
                    Text(isLoading || isUploadingImage ? "Processing..." : (isEditing ? "Save Changes" : "Add to Catalogue"))
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(isLoading || isUploadingImage)
        }
    }

    // MARK: - UI Helpers

    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Rectangle().fill(RSMSTheme.Colors.accentGold).frame(width: 3, height: 16).clipShape(Capsule())
                Text(title).font(.headline).fontWeight(.semibold).foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
            VStack(spacing: RSMSTheme.Spacing.md) { content() }
                .padding(RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    private func fieldLabel(_ label: String, required: Bool) -> some View {
        HStack(spacing: RSMSTheme.Spacing.xs) {
            Text(label).font(.caption).fontWeight(.semibold).foregroundStyle(RSMSTheme.Colors.textSecondary).textCase(.uppercase)
            if required { Text("*").font(.caption).foregroundStyle(RSMSTheme.Colors.error) }
        }
    }

    private func formField(label: String, placeholder: String, text: Binding<String>, icon: String, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
            fieldLabel(label, required: required)
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Image(systemName: icon).foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7)).frame(width: 20)
                TextField("", text: text, prompt: Text(placeholder).foregroundStyle(RSMSTheme.Colors.textTertiary))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
            .padding(RSMSTheme.Spacing.md)
            .background(RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm).stroke(RSMSTheme.Colors.border, lineWidth: 1))
        }
    }

    private func toggleRow(icon: String, label: String, sublabel: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon).font(.title3).foregroundStyle(isOn.wrappedValue ? color : RSMSTheme.Colors.textTertiary).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline).fontWeight(.medium).foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(sublabel).font(.caption).foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            Spacer()
            Toggle("", isOn: isOn).tint(color).labelsHidden()
        }
    }
    
    private func notesField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
            fieldLabel(label, required: false)
            TextEditor(text: text)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .frame(minHeight: 80).scrollContentBackground(.hidden)
                .padding(RSMSTheme.Spacing.sm)
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm).stroke(RSMSTheme.Colors.border, lineWidth: 1))
        }
    }

    // MARK: - Logic & Supabase Integration

    private func uploadImageToSupabase(_ image: UIImage) async throws -> String {
        // 1. Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.2) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        // 2. Create unique path
        let filename = "\(UUID().uuidString).jpg"
        let path = "products/\(filename)"
        
        // 3. Upload raw data with upsert to handle re-uploads during editing
        try await SupabaseManager.shared.client.storage
            .from("product-images")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        
        // 4. Get the Public URL
        // ADD 'try' HERE. It doesn't need 'await' because it's a local string construction.
        let publicUrl = try SupabaseManager.shared.client.storage
            .from("product-images")
            .getPublicURL(path: path)
        
        return publicUrl.absoluteString
    }
    private func saveProduct() {
        showValidationErrors = true
        guard isFormValid else { return }
        
        isLoading = true
        
        Task {
            var finalImageUrl: String? = existingImageUrl
            
            // Handle image upload if a new one is picked
            if let newImage = selectedUIImage {
                isUploadingImage = true
                do {
                    finalImageUrl = try await uploadImageToSupabase(newImage)
                } catch {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                    isLoading = false
                    isUploadingImage = false
                    return
                }
                isUploadingImage = false
            }

            let productToSave = Product(
                id: existingProduct?.id ?? UUID(),
                sku: sku.trimmed.uppercased(),
                name: name.trimmed,
                imageUrl: finalImageUrl, // Assigned here
                category: selectedCategory,
                isActive: isActive,
                isGloballyListed: isGloballyListed,
                createdAt: existingProduct?.createdAt ?? Date(),
                updatedAt: Date(),
                basePrice: Double(basePriceInput) ?? 0,
                material: material.trimmed,
                originCountry: originCountry.trimmed,
                craftsmanshipLevel: selectedCraftsmanship,
                craftsmanshipNotes: craftsmanshipNotes.trimmed,
                collectionName: collectionName.trimmed,
                artisanStudio: artisanStudio.trimmed
            )

            let success: Bool
            if isEditing {
                await appState.updateProduct(productToSave)
                success = appState.productError == nil
            } else {
                success = await appState.addProduct(productToSave)
            }

            isLoading = false
            if success { showSuccessAlert = true }
            else { errorMessage = appState.productError }
        }
    }

    private func populateIfEditing() {
        guard let p = existingProduct else { return }
        sku = p.sku
        name = p.name
        existingImageUrl = p.imageUrl
        selectedCategory = p.category
        basePriceInput = p.basePrice > 0 ? String(format: "%.0f", p.basePrice) : ""
        isActive = p.isActive
        isGloballyListed = p.isGloballyListed
        material = p.material
        originCountry = p.originCountry
        selectedCraftsmanship = p.craftsmanshipLevel
        craftsmanshipNotes = p.craftsmanshipNotes
        collectionName = p.collectionName
        artisanStudio = p.artisanStudio
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
