//
//  StoreDetailView.swift
//  Group5_RSMS
//
//  Corporate Admin — Detail view for a registered boutique.
//  Native inline editing: tap pencil, then tap any value to edit it.
//

import SwiftUI

struct StoreDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let store: Store

    // MARK: - State
    @State private var isEditing = false
    @State private var showDeleteConfirm = false


    // MARK: - Editable Fields (populated on startEditing)
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
    private var isFormValid: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !storeCode.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
                    Button { saveStore() } label: {
                        Image(systemName: "checkmark").font(.body.weight(.semibold))
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
        .onAppear { populateFields() }
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
                TextField("Store Name", text: $storeName)
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .disabled(!isEditing)
                TextField("Store Code", text: $storeCode)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .disabled(!isEditing)
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
            editableRow(icon: "mappin.and.ellipse", label: "Address", text: $address)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "building", label: "City", text: $city)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "map", label: "State", text: $stateField)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "number", label: "ZIP Code", text: $zipCode, keyboard: .numberPad)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "globe", label: "Country", text: $country)
            Divider().background(RSMSTheme.Colors.borderLight)
            pickerRow(icon: "map.circle", label: "Region", selection: $selectedRegion, options: regions)
        }
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        sectionCard(title: "Contact") {
            editableRow(icon: "phone.fill", label: "Phone", text: $phone, keyboard: .phonePad)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "envelope.fill", label: "Email", text: $email, keyboard: .emailAddress)
            Divider().background(RSMSTheme.Colors.borderLight)
            editableRow(icon: "person.fill", label: "Manager", text: $managerName)
        }
    }

    // MARK: - Configuration Section
    private var configSection: some View {
        sectionCard(title: "Configuration") {
            editableRow(icon: "percent", label: "Tax Rate", text: $taxRate, keyboard: .decimalPad)
            Divider().background(RSMSTheme.Colors.borderLight)
            pickerRow(icon: "banknote", label: "Currency", selection: $selectedCurrency,
                      options: currencies.map { $0.code }, displayLabels: Dictionary(uniqueKeysWithValues: currencies.map { ($0.code, $0.label) }))
            Divider().background(RSMSTheme.Colors.borderLight)
            staticRow(icon: "calendar", label: "Registered",
                      value: (liveStore.createdAt ?? Date()).formatted(date: .abbreviated, time: .shortened))
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
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1))
        }
        .confirmationDialog("Delete \(liveStore.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { await appState.deleteStore(liveStore); dismiss() }
            }
        } message: {
            Text("This action cannot be undone. All data associated with this store will be permanently removed.")
        }
    }

    // MARK: - Reusable Components

    /// Section card wrapper
    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    /// Editable row — looks identical to a read-only row, but the value is a TextField
    /// that is disabled when not editing. Tap edit, then tap the value to type.
    private func editableRow(icon: String, label: String, text: Binding<String>,
                             keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
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

    /// Picker row — same layout, but value is a Picker when editing
    private func pickerRow(icon: String, label: String, selection: Binding<String>,
                           options: [String], displayLabels: [String: String]? = nil) -> some View {
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
                Picker("", selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(displayLabels?[option] ?? option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(RSMSTheme.Colors.accentGold)
            } else {
                Text(displayLabels?[selection.wrappedValue] ?? selection.wrappedValue)
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
        }
        .padding(.vertical, RSMSTheme.Spacing.md)
    }

    /// Static read-only row (never editable, e.g. Registered date)
    private func staticRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .padding(.vertical, RSMSTheme.Spacing.md)
    }

    // MARK: - Editing Actions

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
        selectedRegion = liveStore.region ?? "Asia"
        selectedCurrency = liveStore.currencyCode ?? "INR"
        taxRate = String(liveStore.taxRate ?? 18.0)
    }

    private func startEditing() {
        populateFields()
        isEditing = true
    }

    private func cancelEditing() {
        populateFields()   // revert to live values
        isEditing = false
    }

    private func saveStore() {
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
            isEditing = false
        }
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: Store.sample)
    }
    .environment(AppState())
}
