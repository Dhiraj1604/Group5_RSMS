//
//  AddStoreView.swift
//  Group5_RSMS
//
//  Corporate Admin — Register a new boutique store location.
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct AddStoreView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var storeName = ""
    @State private var storeCode = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = "India"
    @State private var phone = ""
    @State private var email = ""
    @State private var managerName = ""
    @State private var managerEmail = ""
    @State private var inventoryName = ""
    @State private var inventoryEmail = ""
    @State private var selectedRegion = "West"
    @State private var selectedCurrency = "INR"
    @State private var monthlyRevenueTarget = "1500000"
    
    // IMAGE STATE
    @State private var selectedUIImage: UIImage? = nil
    @State private var existingImageUrl: String? = nil
    @State private var showImageSourceDialog = false
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingImage = false

    @State private var showValidationErrors = false
    @State private var showSuccessAlert = false
    @State private var isRegistering = false
    @State private var storeToRegister: Store?

    private let regions = ["Asia", "Europe", "North America", "South America", "Australia", "Africa"]

    // 5 major world currencies
    private let currencies: [(code: String, label: String)] = [
        ("INR", "₹  INR — Indian Rupee"),
        ("USD", "$  USD — US Dollar"),
        ("EUR", "€  EUR — Euro"),
        ("GBP", "£  GBP — British Pound"),
        ("JPY", "¥  JPY — Japanese Yen")
    ]

    private var isZipCodeValid: Bool {
        let trimmed = zipCode.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 4 && trimmed.allSatisfy { $0.isNumber }
    }

    private var expectedPhoneLengthRange: ClosedRange<Int> {
        let zipString = zipCode.trimmingCharacters(in: .whitespaces)
        if zipString.count == 6 {
            return 10...10 // e.g., India
        } else if zipString.count == 5 {
            return 10...10 // e.g., USA
        } else if zipString.count == 4 {
            return 9...10 // e.g., Australia
        } else {
            return 8...12 // Fallback for other regions
        }
    }
    
    private var isPhoneValid: Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "+", with: "")
        return expectedPhoneLengthRange.contains(trimmed.count) && trimmed.allSatisfy { $0.isNumber }
    }
    
    private var phoneErrorMessage: String {
        let zipString = zipCode.trimmingCharacters(in: .whitespaces)
        if zipString.count == 6 || zipString.count == 5 {
            return "10 Digits Req"
        } else if zipString.count == 4 {
            return "9-10 Digits Req"
        } else {
            return "8-12 Digits Req"
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let isFormatValid = emailPred.evaluate(with: email)
        // Enforce Gmail validation for testing phase
        return isFormatValid && email.lowercased().hasSuffix("@gmail.com")
    }

    private var isStoreEmailValid: Bool {
        isValidEmail(email.trimmingCharacters(in: .whitespaces))
    }

    private var isManagerEmailValid: Bool {
        isValidEmail(managerEmail.trimmingCharacters(in: .whitespaces))
    }

    private var isInventoryEmailValid: Bool {
        isValidEmail(inventoryEmail.trimmingCharacters(in: .whitespaces))
    }

    private var isFormValid: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !storeCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !state.trimmingCharacters(in: .whitespaces).isEmpty &&
        isZipCodeValid &&
        isPhoneValid &&
        isStoreEmailValid &&
        !managerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isManagerEmailValid &&
        !inventoryName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isInventoryEmailValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        imageUploaderHeader
                        storeInfoSection
                        locationSection
                        contactSection
                        configSection
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle("New Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .disabled(isRegistering)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        registerStore()
                    } label: {
                        if isRegistering || isUploadingImage {
                            ProgressView().tint(RSMSTheme.Colors.accentGold)
                        } else {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .disabled(isRegistering || isUploadingImage)
                }
            }
            .confirmationDialog("Store Image", isPresented: $showImageSourceDialog) {
                Button("Take Photo (Camera)") {
                    imageSource = .camera
                    showImagePicker = true
                }
                Button("Choose from Library") {
                    imageSource = .photoLibrary
                    showImagePicker = true
                }
                if existingImageUrl != nil || selectedUIImage != nil {
                    Button("Remove Image", role: .destructive) {
                        selectedUIImage = nil
                        existingImageUrl = nil
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedUIImage, sourceType: imageSource)
                    .ignoresSafeArea()
            }
            .alert("Boutique Registered! 🎉", isPresented: $showSuccessAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(storeName) has been successfully registered. You can now assign staff and inventory to this location.")
            }
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
                            Text("Add Photo of Store")
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
            .disabled(isRegistering || isUploadingImage)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }

    // MARK: - Store Info
    private var storeInfoSection: some View {
        formSection(title: "Store Information") {
            formField(label: "Store Name", placeholder: "e.g. RSMS Flagship Mumbai", text: $storeName, icon: "building.2", required: true)
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "Store Code", placeholder: "e.g. BTQ-MUM", text: $storeCode, icon: "qrcode", required: true)
                    .textInputAutocapitalization(.characters)
                formField(label: "Monthly Target (₹)", placeholder: "1500000", text: $monthlyRevenueTarget, icon: "target", required: true)
                    .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Location
    private var locationSection: some View {
        formSection(title: "Location") {
            formField(label: "Address", placeholder: "Street address", text: $address, icon: "mappin.and.ellipse", required: true)
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "ZIP Code", placeholder: "ZIP", text: $zipCode, icon: "number", required: true, isValid: isZipCodeValid, errorMessage: "6 Digits")
                    .keyboardType(.numberPad)
                    .onChange(of: zipCode) { _, newZip in autofillFromZip(newZip) }
                formField(label: "Country", placeholder: "Country", text: $country, icon: "globe", required: false)
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "City", placeholder: "City", text: $city, icon: "building", required: true)
                    .onChange(of: city) { _, newCity in autofillFromCity(newCity) }
                formField(label: "State", placeholder: "State", text: $state, icon: "map", required: true)
            }
        }
    }

    private var contactSection: some View {
        formSection(title: "Contact") {
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "Phone", placeholder: "Number", text: $phone, icon: "phone.fill", required: true, isValid: isPhoneValid, errorMessage: phoneErrorMessage)
                    .keyboardType(.phonePad)
                    .onChange(of: phone) { _, newValue in
                        let maxLen = expectedPhoneLengthRange.upperBound
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count > maxLen {
                            phone = String(filtered.prefix(maxLen))
                        } else if phone != filtered {
                            phone = filtered
                        }
                    }
                formField(label: "Store Email", placeholder: "store@gmail.com", text: $email, icon: "envelope.fill", required: true, isValid: isStoreEmailValid, errorMessage: "Requires @gmail.com")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "Manager", placeholder: "Name", text: $managerName, icon: "person.fill", required: true)
                formField(label: "Manager Email", placeholder: "manager@gmail.com", text: $managerEmail, icon: "person.text.rectangle.fill", required: true, isValid: isManagerEmailValid, errorMessage: "Requires @gmail.com")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "Inventory Controller Name", placeholder: "Name", text: $inventoryName, icon: "person.2.fill", required: true)
                formField(label: "Inventory Controller Email", placeholder: "inv@gmail.com", text: $inventoryEmail, icon: "person.text.rectangle", required: true, isValid: isInventoryEmailValid, errorMessage: "Requires @gmail.com")
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
        }
    }

    // MARK: - Configuration
    private var configSection: some View {
        formSection(title: "Configuration") {

            // Region picker (unchanged)
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("Region")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "map.circle.fill")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .frame(width: 20)
                    Picker("Region", selection: $selectedRegion) {
                        ForEach(regions, id: \.self) { region in
                            Text(region).tag(region)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.Colors.textPrimary)
                    Spacer()
                }
                .padding(RSMSTheme.Spacing.md)
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                        .stroke(RSMSTheme.Colors.border, lineWidth: 1)
                )
            }

            // Currency picker
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("Currency")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "banknote.fill")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .frame(width: 20)
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.code) { currency in
                            Text(currency.label).tag(currency.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.Colors.textPrimary)
                    Spacer()
                }
                .padding(RSMSTheme.Spacing.md)
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                        .stroke(RSMSTheme.Colors.border, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Register Button
    // Removed. Registration moved to top navigation bar as requested.

    // MARK: - Helpers
    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            VStack(spacing: RSMSTheme.Spacing.md) {
                content()
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
        }
    }

    private func formField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        required: Bool,
        isValid: Bool = true,
        errorMessage: String? = nil
    ) -> some View {
        let isEmpty = text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty
        let showError = (showValidationErrors && required && isEmpty) || (!isEmpty && !isValid)

        return VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
            HStack(spacing: RSMSTheme.Spacing.xs) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                if required {
                    Text("*")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.error)
                }
                
                Spacer()
                
                if showError, let msg = errorMessage, !isEmpty {
                    Text(msg)
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.Colors.error)
                }
            }
            HStack(spacing: RSMSTheme.Spacing.sm) {
                TextField("", text: text, prompt: Text(placeholder).foregroundStyle(RSMSTheme.Colors.textTertiary))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .autocorrectionDisabled()
            }
            .padding(RSMSTheme.Spacing.md)
            .background(RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                    .stroke(
                        showError
                            ? RSMSTheme.Colors.error.opacity(0.7)
                            : RSMSTheme.Colors.border,
                        lineWidth: 1
                    )
            )
        }
    }

    private func registerStore() {
        showValidationErrors = true
        guard isFormValid else { return }

        self.isRegistering = true
        
        Task {
            var finalImageUrl: String? = existingImageUrl
            
            if let newImage = selectedUIImage {
                isUploadingImage = true
                do {
                    finalImageUrl = try await uploadImageToSupabase(newImage)
                } catch {
                    await MainActor.run {
                        appState.storeError = "Image upload failed: \(error.localizedDescription)"
                        self.isRegistering = false
                        self.isUploadingImage = false
                    }
                    return
                }
                isUploadingImage = false
            }

            let newStore = Store(
                name: storeName.trimmingCharacters(in: .whitespaces),
                city: city.trimmingCharacters(in: .whitespaces),
                country: country.trimmingCharacters(in: .whitespaces),
                code: storeCode.trimmingCharacters(in: .whitespaces).uppercased(),
                phone: phone.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces),
                address: address.trimmingCharacters(in: .whitespaces),
                zipCode: zipCode.trimmingCharacters(in: .whitespaces),
                state: state.trimmingCharacters(in: .whitespaces),
                managerName: managerName.trimmingCharacters(in: .whitespaces),
                region: selectedRegion,
                taxRate: 18.0,
                isActive: true,
                currencyCode: selectedCurrency,
                monthlyRevenueTarget: Double(monthlyRevenueTarget) ?? 1500000.0,
                imageUrl: finalImageUrl
            )
            // 1. Create the store FIRST
            await appState.addStore(newStore)
            
            if let _ = appState.storeError {
                await MainActor.run { self.isRegistering = false }
                return
            }
            
            do {
                // 2. Provision the manager silently via Edge Function
                try await SupabaseManager.shared.provisionAccount(
                    email: managerEmail.trimmingCharacters(in: .whitespaces),
                    storeId: newStore.id,
                    role: "manager"
                )
                
                // 3. Provision the inventory controller silently
                try await SupabaseManager.shared.provisionAccount(
                    email: inventoryEmail.trimmingCharacters(in: .whitespaces),
                    storeId: newStore.id,
                    role: "inventory"
                )
                
                await MainActor.run {
                    self.isRegistering = false
                    self.showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isRegistering = false
                    appState.storeError = "Store created, but failed to provision staff: \(error.localizedDescription)"
                }
            }
        }
    }

    private func uploadImageToSupabase(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.2) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        let filename = "\(UUID().uuidString).jpg"
        let path = "stores/\(filename)"
        
        try await SupabaseManager.shared.client.storage
            .from("product-images")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg", upsert: true))
        
        let publicUrl = try SupabaseManager.shared.client.storage
            .from("product-images")
            .getPublicURL(path: path)
        
        return publicUrl.absoluteString
    }

    // MARK: - Autofill Logic
    private func autofillFromZip(_ zip: String) {
        let zipString = zip.trimmingCharacters(in: .whitespaces)
        if zipString.hasPrefix("400") || zipString.hasPrefix("411") {
            state = "Maharashtra"
            selectedRegion = "Asia"
            if zipString.hasPrefix("400") { city = "Mumbai" }
            if zipString.hasPrefix("411") { city = "Pune" }
        } else if zipString.hasPrefix("110") {
            city = "New Delhi"
            state = "Delhi"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("560") {
            city = "Bengaluru"
            state = "Karnataka"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("600") {
            city = "Chennai"
            state = "Tamil Nadu"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("700") {
            city = "Kolkata"
            state = "West Bengal"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("500") {
            city = "Hyderabad"
            state = "Telangana"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("902") {
            city = "Los Angeles"
            state = "California"
            country = "United States"
            selectedRegion = "North America"
            selectedCurrency = "USD"
        } else if zipString.hasPrefix("100") {
            city = "New York"
            state = "New York"
            country = "United States"
            selectedRegion = "North America"
            selectedCurrency = "USD"
        }
    }

    private func autofillFromCity(_ cityInput: String) {
        let c = cityInput.trimmingCharacters(in: .whitespaces).lowercased()
        switch c {
        case "mumbai", "pune", "nagpur": state = "Maharashtra"
        case "new delhi", "delhi": state = "Delhi"
        case "bengaluru", "bangalore": state = "Karnataka"
        case "chennai": state = "Tamil Nadu"
        case "kolkata": state = "West Bengal"
        case "hyderabad": state = "Telangana"
        case "ahmedabad", "surat": state = "Gujarat"
        case "jaipur": state = "Rajasthan"
        default: break
        }
    }
}

#Preview {
    AddStoreView()
        .environment(AppState())
}
