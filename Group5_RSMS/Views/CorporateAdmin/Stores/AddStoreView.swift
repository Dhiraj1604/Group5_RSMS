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
    @State private var selectedCurrency = "INR"          // ← NEW
    @State private var taxRate = "18.0"
    @State private var showValidationErrors = false
    @State private var showSuccessAlert = false
    @State private var isRegistering = false
    @State private var storeToRegister: Store?

    private let regions = ["Asia", "Europe", "North America", "South America", "Australia", "Africa"]

    // ← NEW: 5 major world currencies
    private let currencies: [(code: String, label: String)] = [
        ("INR", "₹  INR — Indian Rupee"),
        ("USD", "$  USD — US Dollar"),
        ("EUR", "€  EUR — Euro"),
        ("GBP", "£  GBP — British Pound"),
        ("JPY", "¥  JPY — Japanese Yen")
    ]

    private var isZipCodeValid: Bool {
        let trimmed = zipCode.trimmingCharacters(in: .whitespaces)
        return trimmed.count == 6 && trimmed.allSatisfy { $0.isNumber }
    }

    private var isPhoneValid: Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        return trimmed.count == 10 && trimmed.allSatisfy { $0.isNumber }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
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

    private var isTaxRateValid: Bool {
        Double(taxRate) != nil
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
        isInventoryEmailValid &&
        isTaxRateValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        headerSection
                        storeInfoSection
                        locationSection
                        contactSection
                        configSection
                        registerButton
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle("New Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            .alert("Boutique Registered! 🎉", isPresented: $showSuccessAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(storeName) has been successfully registered. You can now assign staff and inventory to this location.")
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 70, height: 70)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            Text("Register a new boutique location")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }

    // MARK: - Store Info
    private var storeInfoSection: some View {
        formSection(title: "Store Information") {
            formField(label: "Store Name", placeholder: "e.g. RSMS Flagship Mumbai", text: $storeName, icon: "building.2", required: true)
            formField(label: "Store Code", placeholder: "e.g. BTQ-MUM-001", text: $storeCode, icon: "qrcode", required: true)
                .textInputAutocapitalization(.characters)
        }
    }

    // MARK: - Location
    private var locationSection: some View {
        formSection(title: "Location") {
            formField(label: "Address", placeholder: "Street address", text: $address, icon: "mappin.and.ellipse", required: true)
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "City", placeholder: "City", text: $city, icon: "building", required: true)
                formField(label: "State", placeholder: "State", text: $state, icon: "map", required: true)
            }
            HStack(spacing: RSMSTheme.Spacing.md) {
                formField(label: "ZIP Code", placeholder: "ZIP", text: $zipCode, icon: "number", required: true, isValid: isZipCodeValid, errorMessage: "6 Digits")
                    .keyboardType(.numberPad)
                formField(label: "Country", placeholder: "Country", text: $country, icon: "globe", required: false)
            }
        }
    }

    // MARK: - Contact
    private var contactSection: some View {
        formSection(title: "Contact") {
            formField(label: "Phone", placeholder: "10-digit number", text: $phone, icon: "phone.fill", required: true, isValid: isPhoneValid, errorMessage: "10 Digits")
                .keyboardType(.phonePad)
            formField(label: "Store Email", placeholder: "store@rsms.com", text: $email, icon: "envelope.fill", required: true, isValid: isStoreEmailValid, errorMessage: "Invalid Email")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            formField(label: "Manager Name", placeholder: "Store manager name", text: $managerName, icon: "person.fill", required: true)
            formField(label: "Manager Email", placeholder: "manager@example.com", text: $managerEmail, icon: "person.text.rectangle.fill", required: true, isValid: isManagerEmailValid, errorMessage: "Invalid Email")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            formField(label: "Inventory Controller Name", placeholder: "Inventory controller name", text: $inventoryName, icon: "person.2.fill", required: true)
            formField(label: "Inventory Email", placeholder: "inventory@example.com", text: $inventoryEmail, icon: "person.text.rectangle", required: true, isValid: isInventoryEmailValid, errorMessage: "Invalid Email")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
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

            // ← NEW: Currency picker
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

            formField(label: "Tax Rate (%)", placeholder: "18.0", text: $taxRate, icon: "percent", required: true, isValid: isTaxRateValid, errorMessage: "Invalid Rate")
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Register Button
    private var registerButton: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            if showValidationErrors && !isFormValid {
                Text("Please fill in all required fields.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.error)
            }
            Button { registerStore() } label: {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    if isRegistering {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Register Boutique")
                    }
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(isRegistering)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }

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
        let showError = showValidationErrors && (!isValid || (required && isEmpty))

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
                Image(systemName: icon)
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                    .frame(width: 20)
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
            taxRate: Double(taxRate) ?? 18.0,
            isActive: true,
            currencyCode: selectedCurrency
        )
        self.isRegistering = true
        
        Task {
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
}

#Preview {
    AddStoreView()
        .environment(AppState())
}
