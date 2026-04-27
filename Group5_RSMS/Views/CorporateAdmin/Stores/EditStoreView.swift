//
//  EditStoreView.swift
//  Group5_RSMS
//
//  Corporate Admin — Edit an existing boutique store location.
//

import SwiftUI

struct EditStoreView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let store: Store

    @State private var storeName: String
    @State private var storeCode: String
    @State private var address: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String
    @State private var phone: String
    @State private var email: String
    @State private var managerName: String
    @State private var selectedRegion: String
    @State private var selectedCurrency: String
    @State private var isActive: Bool
    @State private var taxRate: String
    @State private var showValidationErrors = false
    @State private var showSuccessAlert = false

    private let regions = ["Asia", "Europe", "North America", "South America", "Australia", "Africa"]

    private let currencies: [(code: String, label: String)] = [
        ("INR", "₹  INR — Indian Rupee"),
        ("USD", "$  USD — US Dollar"),
        ("EUR", "€  EUR — Euro"),
        ("GBP", "£  GBP — British Pound"),
        ("JPY", "¥  JPY — Japanese Yen")
    ]

    init(store: Store) {
        self.store = store
        _storeName   = State(initialValue: store.name)
        _storeCode   = State(initialValue: store.code)
        _address     = State(initialValue: store.address ?? "")
        _city        = State(initialValue: store.city)
        _state       = State(initialValue: store.state ?? "")
        _zipCode     = State(initialValue: store.zipCode ?? "")
        _country     = State(initialValue: store.country)
        _phone       = State(initialValue: store.phone ?? "")
        _email       = State(initialValue: store.email ?? "")
        _managerName = State(initialValue: store.managerName ?? "")
        _selectedRegion = State(initialValue: store.region ?? "Asia")
        _selectedCurrency = State(initialValue: store.currencyCode ?? "INR")
        _isActive    = State(initialValue: store.isActive)
        _taxRate     = State(initialValue: String(store.taxRate ?? 18.0))
    }

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
                        saveButton
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle("Edit Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            .alert("Store Updated! 🎉", isPresented: $showSuccessAlert) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(storeName) details have been successfully updated.")
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
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            Text("Update boutique location details")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }

    // MARK: - Store Info
    private var storeInfoSection: some View {
        formSection(title: "Store Information") {
            // Read-only ID
            HStack {
                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                    Text("Store ID")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                    Text(store.id.uuidString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
            .padding(.bottom, RSMSTheme.Spacing.sm)

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
            formField(label: "Email", placeholder: "store@rsms.com", text: $email, icon: "envelope.fill", required: true, isValid: isStoreEmailValid, errorMessage: "Invalid Email")
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            formField(label: "Manager Name", placeholder: "Store manager name", text: $managerName, icon: "person.fill", required: true)
        }
    }

    // MARK: - Configuration
    private var configSection: some View {
        formSection(title: "Configuration") {
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

            formField(label: "Tax Rate (%)", placeholder: "18.0", text: $taxRate, icon: "percent", required: true, isValid: isTaxRateValid, errorMessage: "Invalid Rate")
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            if showValidationErrors && !isFormValid {
                Text("Please fill in all required fields.")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.error)
            }
            Button { saveStore() } label: {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Changes")
                }
            }
            .buttonStyle(GoldButtonStyle())
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

    private func saveStore() {
        showValidationErrors = true
        guard isFormValid else { return }

        var updatedStore = store
        updatedStore.name = storeName.trimmingCharacters(in: .whitespaces)  // .storeName → .name
        updatedStore.code = storeCode.trimmingCharacters(in: .whitespaces).uppercased()
        updatedStore.address = address.trimmingCharacters(in: .whitespaces)
        updatedStore.city = city.trimmingCharacters(in: .whitespaces)
        updatedStore.state = state.trimmingCharacters(in: .whitespaces)
        updatedStore.zipCode = zipCode.trimmingCharacters(in: .whitespaces)
        updatedStore.country = country.trimmingCharacters(in: .whitespaces)
        updatedStore.phone = phone.trimmingCharacters(in: .whitespaces)
        updatedStore.email = email.trimmingCharacters(in: .whitespaces)
        updatedStore.managerName = managerName.trimmingCharacters(in: .whitespaces)
        updatedStore.region = selectedRegion
        updatedStore.currencyCode = selectedCurrency
        updatedStore.isActive = isActive
        updatedStore.taxRate = Double(taxRate) ?? store.taxRate ?? 18.0

        Task {
            await appState.updateStoreDetails(updatedStore)
            showSuccessAlert = true
        }
    }
}

#Preview {
    EditStoreView(store: Store.sample)
        .environment(AppState())
}
