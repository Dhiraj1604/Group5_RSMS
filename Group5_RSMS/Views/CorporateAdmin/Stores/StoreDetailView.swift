//
//  StoreDetailView.swift
//  Group5_RSMS
//
//  Corporate Admin — Detail view for a registered boutique.
//  Cinematic Split-Screen Layout with Live Revenue Tracking.
//

import SwiftUI
import Supabase

struct StoreDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let store: Store

    init(store: Store) {
        self.store = store
    }

    // MARK: - State
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    @State private var currentRevenue: Double = 0.0
    @State private var isLoadingRevenue = false

    // MARK: - Editable Fields
    @State private var storeName: String = ""
    @State private var storeCode: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var stateField: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var managerName: String = ""
    @State private var selectedRegion: String = "Asia"
    @State private var selectedCurrency: String = "INR"
    @State private var taxRate: String = "18.0"
    @State private var monthlyTarget: String = "0"
    @State private var imageUrl: String = ""

    // MARK: - Image Upload & Validation State
    @State private var showValidationErrors = false
    @State private var selectedUIImage: UIImage? = nil
    @State private var showImageSourceDialog = false
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploadingImage = false

    private let regions = ["Asia", "Europe", "North America", "South America", "Australia", "Africa", "MEIA"]
    private let currencies: [(code: String, label: String)] = [
        ("INR", "₹ INR"), ("USD", "$ USD"), ("EUR", "€ EUR"), ("GBP", "£ GBP"), ("JPY", "¥ JPY"), ("AED", "د.إ AED")
    ]

    private var liveStore: Store {
        appState.stores.first(where: { $0.id == store.id }) ?? store
    }

    // MARK: - Validation & Autofill Logic
    private var isZipCodeValid: Bool {
        let trimmed = zipCode.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 4 && trimmed.allSatisfy { $0.isNumber }
    }

    private var expectedPhoneLengthRange: ClosedRange<Int> {
        let zipString = zipCode.trimmingCharacters(in: .whitespaces)
        if zipString.count == 6 || zipString.count == 5 {
            return 10...10
        } else if zipString.count == 4 {
            return 9...10
        } else {
            return 8...12
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
        return emailPred.evaluate(with: email) && email.lowercased().hasSuffix("@gmail.com")
    }

    private var isStoreEmailValid: Bool { isValidEmail(email.trimmingCharacters(in: .whitespaces)) }

    private var isFormValid: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !storeCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !stateField.trimmingCharacters(in: .whitespaces).isEmpty &&
        isZipCodeValid &&
        isPhoneValid &&
        isStoreEmailValid
    }
    
    private func autofillFromZip(_ zip: String) {
        let zipString = zip.trimmingCharacters(in: .whitespaces)
        if zipString.hasPrefix("400") || zipString.hasPrefix("411") {
            stateField = "Maharashtra"
            selectedRegion = "Asia"
            if zipString.hasPrefix("400") { city = "Mumbai" }
            if zipString.hasPrefix("411") { city = "Pune" }
        } else if zipString.hasPrefix("110") {
            city = "New Delhi"
            stateField = "Delhi"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("560") {
            city = "Bengaluru"
            stateField = "Karnataka"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("600") {
            city = "Chennai"
            stateField = "Tamil Nadu"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("700") {
            city = "Kolkata"
            stateField = "West Bengal"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("500") {
            city = "Hyderabad"
            stateField = "Telangana"
            selectedRegion = "Asia"
        } else if zipString.hasPrefix("902") {
            city = "Los Angeles"
            stateField = "California"
            country = "United States"
            selectedRegion = "North America"
            selectedCurrency = "USD"
        } else if zipString.hasPrefix("100") {
            city = "New York"
            stateField = "New York"
            country = "United States"
            selectedRegion = "North America"
            selectedCurrency = "USD"
        }
    }

    private func autofillFromCity(_ cityInput: String) {
        let c = cityInput.trimmingCharacters(in: .whitespaces).lowercased()
        switch c {
        case "mumbai", "pune", "nagpur": stateField = "Maharashtra"
        case "new delhi", "delhi": stateField = "Delhi"
        case "bengaluru", "bangalore": stateField = "Karnataka"
        case "chennai": stateField = "Tamil Nadu"
        case "kolkata": stateField = "West Bengal"
        case "hyderabad": stateField = "Telangana"
        case "ahmedabad", "surat": stateField = "Gujarat"
        case "jaipur": stateField = "Rajasthan"
        default: break
        }
    }
    
    private var progress: Double {
        let targetValue = Double(monthlyTarget) ?? liveStore.monthlyRevenueTarget ?? 1.0
        let target = max(targetValue, 1.0)
        return min(currentRevenue / target, 1.0)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            GeometryReader { geo in
                HStack(alignment: .top, spacing: 0) {
                    // LEFT COLUMN: Profile Sidebar
                    leftSidebar(width: geo.size.width * 0.35)
                    
                    Divider()
                        .background(RSMSTheme.Colors.borderLight)
                        .padding(.vertical, 40)

                    // RIGHT COLUMN: Detailed Information
                    rightContent
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button { cancelEditing() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color(white: 0.4))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { saveStore() } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
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
        .confirmationDialog("Store Image", isPresented: $showImageSourceDialog) {
            Button("Take Photo (Camera)") {
                imageSource = .camera
                showImagePicker = true
            }
            Button("Choose from Library") {
                imageSource = .photoLibrary
                showImagePicker = true
            }
            if selectedUIImage != nil || (liveStore.imageUrl != nil) {
                Button("Remove Image", role: .destructive) {
                    selectedUIImage = nil
                    imageUrl = "deleted"
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedUIImage, sourceType: imageSource)
                .ignoresSafeArea()
        }
        .onAppear { 
            populateFields()
            fetchLiveRevenue()
        }
    }

    // MARK: - Left Sidebar
    private func leftSidebar(width: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // 1. Store Image
                ZStack {
                    let finalImageName = imageUrl.isEmpty ? (liveStore.imageUrl ?? liveStore.name) : (imageUrl == "deleted" ? liveStore.name : imageUrl)
                    
                    if let newImg = selectedUIImage {
                        Image(uiImage: newImg).resizable().scaledToFill()
                    } else if finalImageName.hasPrefix("http") {
                        AsyncImage(url: URL(string: finalImageName)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                fallbackIcon
                            }
                        }
                    } else {
                        Image(finalImageName)
                            .resizable()
                            .scaledToFill()
                            .overlay {
                                if UIImage(named: finalImageName) == nil {
                                    Image(liveStore.city).resizable().scaledToFill()
                                }
                            }
                            .overlay {
                                if UIImage(named: finalImageName) == nil && UIImage(named: liveStore.city) == nil {
                                    fallbackIcon
                                }
                            }
                    }
                    
                    if isEditing {
                        Color.black.opacity(0.4)
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                            Text("Change Photo")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                    }
                    
                    if isUploadingImage {
                        Color.black.opacity(0.7)
                        ProgressView().tint(.white)
                    }
                }
                .frame(width: width - 80, height: width - 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 10)
                .padding(.horizontal, 40)
                .onTapGesture {
                    if isEditing { showImageSourceDialog = true }
                }

                // 2. Store Identity
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        TextField("Store Name", text: $storeName, axis: .vertical)
                            .font(.custom("HelveticaNeue-Bold", size: 34))
                            .foregroundStyle(.white)
                            .disabled(!isEditing)
                            .lineLimit(3)
                        
                        Circle()
                            .fill(liveStore.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                            .frame(width: 12, height: 12)
                            .padding(.top, 12)
                    }
                    
                    // Inline Region Dropdown
                    if isEditing {
                        Menu {
                            ForEach(regions, id: \.self) { region in
                                Button(region) { selectedRegion = region }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedRegion.uppercased())
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .font(.custom("HelveticaNeue-Bold", size: 14))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .tracking(2)
                        }
                    } else {
                        Text(liveStore.region.uppercased())
                            .font(.custom("HelveticaNeue-Bold", size: 14))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .tracking(2)
                    }
                }
                .padding(.horizontal, 40)

                // 3. Performance Metric & Target Progress
                VStack(alignment: .leading, spacing: 32) {
                    // Revenue of this Month
                    VStack(alignment: .leading, spacing: 10) {
                        Text("REVENUE OF THIS MONTH")
                            .font(.custom("HelveticaNeue-Bold", size: 12))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .tracking(1.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            if isLoadingRevenue {
                                ProgressView().tint(RSMSTheme.Colors.accentGold)
                            } else {
                                Text("\(selectedCurrency) \(formatCurrencyValue(currentRevenue))")
                                    .font(.custom("HelveticaNeue-Bold", size: 34))
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                                
                                if selectedCurrency != "INR" {
                                    let conversionRate = selectedCurrency == "AED" ? 22.7 : 83.0
                                    let rupeeValue = currentRevenue * conversionRate
                                    Text("(₹ \(formatCurrencyValue(rupeeValue, forceIndian: true)))")
                                        .font(.custom("HelveticaNeue-Medium", size: 18))
                                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Monthly Revenue Target
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MONTHLY REVENUE TARGET")
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .tracking(1.5)
                        
                        HStack(spacing: 8) {
                            Text(selectedCurrency)
                                .font(.custom("HelveticaNeue-Bold", size: 18))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                            
                            if isEditing {
                                TextField("Target", text: $monthlyTarget)
                                    .font(.custom("HelveticaNeue-Bold", size: 24))
                                    .foregroundStyle(.white)
                                    .keyboardType(.decimalPad)
                            } else {
                                Text(formatCurrencyValue(Double(monthlyTarget) ?? 0))
                                    .font(.custom("HelveticaNeue-Bold", size: 24))
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        // Progress Bar
                        VStack(alignment: .leading, spacing: 10) {
                            GeometryReader { barGeo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(RSMSTheme.Colors.accentGold)
                                        .frame(width: barGeo.size.width * progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(Int(progress * 100))% of monthly target achieved")
                                .font(.custom("HelveticaNeue-Medium", size: 14))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 40)

                // 4. Action Buttons
                VStack(spacing: 16) {
                    Button {
                        Task { await appState.toggleStoreActive(liveStore) }
                    } label: {
                        HStack {
                            Image(systemName: (liveStore.isActive == true) ? "pause.circle.fill" : "play.circle.fill")
                            Text((liveStore.isActive == true) ? "Deactivate Store" : "Activate Store")
                        }
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                    }
                    
                    Button { showDeleteConfirm = true } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Store")
                        }
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RSMSTheme.Colors.error.opacity(0.1))
                        .foregroundStyle(RSMSTheme.Colors.error)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 40)
        }
        .frame(width: width)
    }

    // MARK: - Right Content
    private var rightContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                
                // SECTION: Location & Logistics
                detailSection(title: "Location & Logistics") {
                    editableDetailRow(icon: "mappin.and.ellipse", label: "Address", text: $address)
                    Divider().background(RSMSTheme.Colors.borderLight)
                    editableDetailRow(icon: "building", label: "City", text: $city)
                        .onChange(of: city) { _, newCity in if isEditing { autofillFromCity(newCity) } }
                    Divider().background(RSMSTheme.Colors.borderLight)
                    editableDetailRow(icon: "map", label: "State", text: $stateField)
                    Divider().background(RSMSTheme.Colors.borderLight)
                    editableDetailRow(icon: "number", label: "ZIP Code", text: $zipCode, keyboard: .numberPad, isValid: isZipCodeValid, errorMessage: "Invalid ZIP")
                        .onChange(of: zipCode) { _, newZip in if isEditing { autofillFromZip(newZip) } }
                    Divider().background(RSMSTheme.Colors.borderLight)
                    editableDetailRow(icon: "globe", label: "Country", text: $country)
                }

                // SECTION: Contact & Management
                detailSection(title: "Contact & Management") {
                    editableDetailRow(icon: "phone.fill", label: "Phone", text: $phone, keyboard: .phonePad, isValid: isPhoneValid, errorMessage: phoneErrorMessage)
                        .onChange(of: phone) { _, newValue in
                            if isEditing {
                                let maxLen = expectedPhoneLengthRange.upperBound
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > maxLen {
                                    phone = String(filtered.prefix(maxLen))
                                } else if phone != filtered {
                                    phone = filtered
                                }
                            }
                        }
                    Divider().background(RSMSTheme.Colors.borderLight)
                    editableDetailRow(icon: "envelope.fill", label: "Email", text: $email, keyboard: .emailAddress, isValid: isStoreEmailValid, errorMessage: "Requires @gmail.com")
                    Divider().background(RSMSTheme.Colors.borderLight)
                    editableDetailRow(icon: "person.fill", label: "Manager", text: $managerName)
                    
                    Divider().background(RSMSTheme.Colors.borderLight)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                            Text("BOUTIQUE NOTES")
                                .font(.custom("HelveticaNeue-Bold", size: 12))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                .tracking(1)
                        }
                        Text("This flagship boutique represents the pinnacle of Dior's presence in the region, featuring bespoke architectural details and housing our most exclusive collections.")
                            .font(.custom("HelveticaNeue", size: 17))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            .lineSpacing(6)
                    }
                    .padding(.vertical, 16)
                    
                    Divider().background(RSMSTheme.Colors.borderLight)
                    detailRow(icon: "calendar", label: "Registered", value: (liveStore.createdAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                }
                
                // Advanced Configuration hidden fields
                if isEditing {
                     detailSection(title: "Configuration") {
                         pickerDetailRow(icon: "banknote", label: "Currency", selection: $selectedCurrency,
                                         options: currencies.map { $0.code }, displayLabels: Dictionary(uniqueKeysWithValues: currencies.map { ($0.code, $0.label) }))
                     }
                }
                
                Spacer().frame(height: 60)
            }
            .padding(40)
        }
    }

    // MARK: - Reusable Components
    
    private func detailSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(RSMSTheme.Colors.accentGold)
                    .frame(width: 4, height: 22)
                Text(title)
                    .font(.custom("HelveticaNeue-Bold", size: 22))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 24)
            .background(RSMSTheme.Colors.backgroundDeep.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    private func detailRow(icon: String, label: String, value: String, valueColor: Color = .white) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                .frame(width: 20)
            Text(label)
                .font(.custom("HelveticaNeue", size: 19))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.custom("HelveticaNeue-Medium", size: 19))
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 22)
    }

    private func editableDetailRow(icon: String, label: String, text: Binding<String>, keyboard: UIKeyboardType = .default, isValid: Bool = true, errorMessage: String? = nil) -> some View {
        let isEmpty = text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty
        let showError = isEditing && ((showValidationErrors && isEmpty) || (!isEmpty && !isValid))

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(showError ? RSMSTheme.Colors.error : RSMSTheme.Colors.accentGold.opacity(0.7))
                    .frame(width: 20)
                Text(label)
                    .font(.custom("HelveticaNeue", size: 19))
                    .foregroundStyle(showError ? RSMSTheme.Colors.error : RSMSTheme.Colors.textSecondary)
                Spacer()
                TextField("—", text: text)
                    .font(.custom("HelveticaNeue-Medium", size: 19))
                    .foregroundStyle(showError ? RSMSTheme.Colors.error : .white)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
                    .disabled(!isEditing)
            }
            .padding(.vertical, 22)
            
            if showError, let msg = errorMessage, !isEmpty {
                Text(msg)
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.error)
                    .padding(.leading, 36)
                    .padding(.bottom, 8)
            }
        }
    }

    private func pickerDetailRow(icon: String, label: String, selection: Binding<String>, options: [String], displayLabels: [String: String]? = nil) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                .frame(width: 20)
            Text(label)
                .font(.custom("HelveticaNeue", size: 19))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            if isEditing {
                Picker("", selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayLabels?[option] ?? option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(RSMSTheme.Colors.accentGold)
            } else {
                Text(displayLabels?[selection.wrappedValue] ?? selection.wrappedValue)
                    .font(.custom("HelveticaNeue-Medium", size: 19))
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 22)
    }

    private var fallbackIcon: some View {
        RSMSTheme.Colors.backgroundDeep
            .overlay(
                Image(systemName: "storefront.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.2))
            )
    }

    private func formatCurrencyValue(_ value: Double, forceIndian: Bool = false) -> String {
        let isIndian = forceIndian || (selectedCurrency == "INR")
        
        if isIndian {
            if value >= 10_000_000 {
                return String(format: "%.1f Cr", value / 10_000_000)
            } else if value >= 100_000 {
                return String(format: "%.1f L", value / 100_000)
            } else if value >= 1_000 {
                return String(format: "%.1f K", value / 1_000)
            } else {
                return String(format: "%.0f", value)
            }
        } else {
            // International standards
            if value >= 1_000_000_000 {
                return String(format: "%.1f B", value / 1_000_000_000)
            } else if value >= 1_000_000 {
                return String(format: "%.1f M", value / 1_000_000)
            } else if value >= 1_000 {
                return String(format: "%.1f K", value / 1_000)
            } else {
                return String(format: "%.0f", value)
            }
        }
    }

    // MARK: - Logic
    private func fetchLiveRevenue() {
        isLoadingRevenue = true
        Task {
            do {
                let response = try await SupabaseManager.shared.client
                    .from("customer_orders")
                    .select("total_amount")
                    .eq("store_id", value: liveStore.id.uuidString)
                    .execute()
                
                struct RevenueRecord: Codable { let total_amount: Double }
                let records = try JSONDecoder().decode([RevenueRecord].self, from: response.data)
                let total = records.reduce(0) { $0 + $1.total_amount }
                
                await MainActor.run {
                    self.currentRevenue = total
                    self.isLoadingRevenue = false
                }
            } catch {
                print("Failed to fetch revenue: \(error)")
                await MainActor.run { self.isLoadingRevenue = false }
            }
        }
    }

    private func populateFields() {
        storeName = liveStore.name
        storeCode = liveStore.code
        address = liveStore.address ?? ""
        city = liveStore.city
        stateField = liveStore.state ?? ""
        zipCode = liveStore.zipCode ?? ""
        country = liveStore.country
        phone = liveStore.phone ?? ""
        email = liveStore.email ?? ""
        managerName = liveStore.managerName ?? ""
        selectedRegion = liveStore.region
        selectedCurrency = liveStore.currencyCode ?? "INR"
        taxRate = String(liveStore.taxRate ?? 18.0)
        monthlyTarget = String(Int(liveStore.monthlyRevenueTarget ?? 1500000.0))
        imageUrl = liveStore.imageUrl ?? ""
    }

    private func startEditing() { 
        populateFields()
        showValidationErrors = false
        selectedUIImage = nil
        isEditing = true 
    }
    private func cancelEditing() { 
        populateFields()
        showValidationErrors = false
        selectedUIImage = nil
        isEditing = false 
    }
    private func saveStore() {
        showValidationErrors = true
        guard isFormValid else { return }
        
        Task {
            var finalImageUrl: String? = (imageUrl == "deleted") ? nil : imageUrl
            
            if let newImage = selectedUIImage {
                isUploadingImage = true
                do {
                    finalImageUrl = try await uploadImageToSupabase(newImage)
                } catch {
                    print("Failed to upload image: \(error)")
                }
                isUploadingImage = false
            }

            var updatedStore = liveStore
        updatedStore.name = storeName.trimmingCharacters(in: .whitespaces)
        updatedStore.code = storeCode.trimmingCharacters(in: .whitespaces).uppercased()
        updatedStore.address = address.trimmingCharacters(in: .whitespaces)
        updatedStore.city = city.trimmingCharacters(in: .whitespaces)
        updatedStore.state = stateField.trimmingCharacters(in: .whitespaces)
        updatedStore.zipCode = zipCode.trimmingCharacters(in: .whitespaces)
        updatedStore.country = country.trimmingCharacters(in: .whitespaces)
        updatedStore.phone = phone.trimmingCharacters(in: .whitespaces)
        updatedStore.email = email.trimmingCharacters(in: .whitespaces)
        updatedStore.managerName = managerName.trimmingCharacters(in: .whitespaces)
        updatedStore.region = selectedRegion
        updatedStore.currencyCode = selectedCurrency
        updatedStore.monthlyRevenueTarget = Double(monthlyTarget) ?? liveStore.monthlyRevenueTarget
        updatedStore.imageUrl = finalImageUrl

        await appState.updateStoreDetails(updatedStore)
        await MainActor.run {
            isEditing = false
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
}
