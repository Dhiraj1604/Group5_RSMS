//
//  StoreDetailView.swift
//  Group5_RSMS
//
//  Corporate Admin — Detail view for a registered boutique.
//  Supports inline editing: tap pencil to edit values in-place.
//

import SwiftUI

struct StoreDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let store: Store

    // MARK: - Editing State
    @State private var isEditing = false
    @State private var showDeleteConfirm = false
    @State private var showValidationErrors = false
    @State private var showSuccessAlert = false

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

    private let regions = ["Asia", "Europe", "North America", "South America", "Australia", "Africa"]
    private let currencies: [(code: String, label: String)] = [
        ("INR", "₹ INR"), ("USD", "$ USD"), ("EUR", "€ EUR"), ("GBP", "£ GBP"), ("JPY", "¥ JPY")
    ]

    private var liveStore: Store {
        appState.stores.first(where: { $0.id == store.id }) ?? store
    }

    // MARK: - Validation
    private var isZipCodeValid: Bool {
        let trimmed = zipCode.trimmingCharacters(in: .whitespaces)
        return trimmed.count == 6 && trimmed.allSatisfy { $0.isNumber }
    }
    private var isPhoneValid: Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespaces)
        return trimmed.count == 10 && trimmed.allSatisfy { $0.isNumber }
    }
    private var isStoreEmailValid: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex)
            .evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }
    private var isTaxRateValid: Bool { Double(taxRate) != nil }

    private var isFormValid: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !storeCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !stateField.trimmingCharacters(in: .whitespaces).isEmpty &&
        isZipCodeValid && isPhoneValid && isStoreEmailValid &&
        !managerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isTaxRateValid
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    headerCard
                    locationSection
                    contactSection
                    configSection
                    statusToggle
                    deleteButton
                    Spacer().frame(height: RSMSTheme.Spacing.xxl)
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
            }
        }
        .navigationTitle(liveStore.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button { cancelEditing() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { saveStore() } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startEditing() } label: {
                        Image(systemName: "pencil")
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .alert("Store Updated! 🎉", isPresented: $showSuccessAlert) {
            Button("Done") { }
        } message: {
            Text("\(storeName) details have been successfully updated.")
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill((liveStore.isActive == true)
                          ? RSMSTheme.Colors.accentGold.opacity(0.15)
                          : RSMSTheme.Colors.textTertiary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 36))
                    .foregroundStyle((liveStore.isActive == true)
                                     ? RSMSTheme.Colors.accentGold
                                     : RSMSTheme.Colors.textTertiary)
            }

            VStack(spacing: RSMSTheme.Spacing.xs) {
                if isEditing {
                    TextField("Store Name", text: $storeName)
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, RSMSTheme.Spacing.md)
                        .padding(.vertical, RSMSTheme.Spacing.sm)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                            .stroke(RSMSTheme.Colors.accentGold.opacity(0.3), lineWidth: 1))

                    TextField("Store Code", text: $storeCode)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, RSMSTheme.Spacing.md)
                        .padding(.vertical, RSMSTheme.Spacing.sm)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                            .stroke(RSMSTheme.Colors.accentGold.opacity(0.3), lineWidth: 1))
                } else {
                    Text(liveStore.name)
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text(liveStore.code)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }

            Text((liveStore.isActive == true) ? "● Active" : "● Inactive")
                .font(.caption).fontWeight(.bold)
                .foregroundStyle((liveStore.isActive == true) ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(
                    ((liveStore.isActive == true) ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                        .opacity(0.12)
                )
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Location Section
    private var locationSection: some View {
        sectionCard(title: "Location") {
            inlineRow(icon: "mappin.and.ellipse", label: "Address", text: $address,
                      readValue: liveStore.address ?? "—")
            Divider().background(RSMSTheme.Colors.borderLight)
            inlineRow(icon: "building", label: "City", text: $city,
                      readValue: liveStore.city)
            Divider().background(RSMSTheme.Colors.borderLight)
            inlineRow(icon: "map", label: "State", text: $stateField,
                      readValue: liveStore.state ?? "—")
            Divider().background(RSMSTheme.Colors.borderLight)
            inlineRow(icon: "number", label: "ZIP Code", text: $zipCode,
                      readValue: liveStore.zipCode ?? "—", keyboard: .numberPad)
            Divider().background(RSMSTheme.Colors.borderLight)
            inlineRow(icon: "globe", label: "Country", text: $country,
                      readValue: liveStore.country)
            Divider().background(RSMSTheme.Colors.borderLight)

            // Region — picker in edit mode, text in read mode
            HStack(spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "map.circle")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                    .frame(width: 24)
                Text("Region")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                if isEditing {
                    Picker("", selection: $selectedRegion) {
                        ForEach(regions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.Colors.accentGold)
                } else {
                    Text(liveStore.region ?? "—")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
            }
            .padding(.vertical, RSMSTheme.Spacing.md)
        }
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        sectionCard(title: "Contact") {
            inlineRow(icon: "phone.fill", label: "Phone", text: $phone,
                      readValue: liveStore.phone ?? "—", keyboard: .phonePad)
            Divider().background(RSMSTheme.Colors.borderLight)
            inlineRow(icon: "envelope.fill", label: "Email", text: $email,
                      readValue: liveStore.email ?? "—", keyboard: .emailAddress, autocap: false)
            Divider().background(RSMSTheme.Colors.borderLight)
            inlineRow(icon: "person.fill", label: "Manager", text: $managerName,
                      readValue: liveStore.managerName ?? "—")
        }
    }

    // MARK: - Configuration Section
    private var configSection: some View {
        sectionCard(title: "Configuration") {
            inlineRow(icon: "percent", label: "Tax Rate", text: $taxRate,
                      readValue: liveStore.formattedTaxRate, keyboard: .decimalPad)
            Divider().background(RSMSTheme.Colors.borderLight)

            // Currency — picker in edit mode, text in read mode
            HStack(spacing: RSMSTheme.Spacing.md) {
                Image(systemName: "banknote")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                    .frame(width: 24)
                Text("Currency")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                if isEditing {
                    Picker("", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.code) { Text($0.label).tag($0.code) }
                    }
                    .pickerStyle(.menu)
                    .tint(RSMSTheme.Colors.accentGold)
                } else {
                    Text(liveStore.currencyCode ?? "—")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
            }
            .padding(.vertical, RSMSTheme.Spacing.md)

            if !isEditing {
                Divider().background(RSMSTheme.Colors.borderLight)
                HStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                        .frame(width: 24)
                    Text("Registered")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Spacer()
                    Text((liveStore.createdAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
                .padding(.vertical, RSMSTheme.Spacing.md)
            }
        }
    }

    // MARK: - Status Toggle
    private var statusToggle: some View {
        Button {
            Task { await appState.toggleStoreActive(liveStore) }
        } label: {
            HStack {
                Image(systemName: (liveStore.isActive == true) ? "pause.circle.fill" : "play.circle.fill")
                Text((liveStore.isActive == true) ? "Deactivate Store" : "Activate Store")
            }
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    // MARK: - Delete
    private var deleteButton: some View {
        Button { showDeleteConfirm = true } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Store")
            }
            .font(.headline).fontWeight(.medium)
            .foregroundStyle(RSMSTheme.Colors.error)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(RSMSTheme.Colors.error.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1)
            )
        }
        .confirmationDialog("Delete \(liveStore.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await appState.deleteStore(liveStore); dismiss() }
            }
        } message: {
            Text("This action cannot be undone. All data associated with this store will be permanently removed.")
        }
    }

    // MARK: - Reusable Section Card
    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
        }
    }

    // MARK: - Inline Row (read → text, edit → textfield)
    private func inlineRow(
        icon: String, label: String, text: Binding<String>,
        readValue: String, keyboard: UIKeyboardType = .default, autocap: Bool = true
    ) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            if isEditing {
                TextField(label, text: text)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocap ? .words : .never)
                    .autocorrectionDisabled()
            } else {
                Text(readValue)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, RSMSTheme.Spacing.md)
    }

    // MARK: - Editing Actions
    private func startEditing() {
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
        selectedRegion = liveStore.region ?? "Asia"
        selectedCurrency = liveStore.currencyCode ?? "INR"
        taxRate = String(liveStore.taxRate ?? 18.0)
        showValidationErrors = false
        withAnimation(.easeInOut(duration: 0.2)) { isEditing = true }
    }

    private func cancelEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
            showValidationErrors = false
        }
    }

    private func saveStore() {
        showValidationErrors = true
        guard isFormValid else { return }

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
        updatedStore.taxRate = Double(taxRate) ?? liveStore.taxRate ?? 18.0

        Task {
            await appState.updateStoreDetails(updatedStore)
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = false
                showValidationErrors = false
            }
            showSuccessAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: Store.sample)
    }
    .environment(AppState())
}
