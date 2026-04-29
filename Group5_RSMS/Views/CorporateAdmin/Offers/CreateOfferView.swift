//
//  CreateOfferView.swift
//  Group5_RSMS
//
//  Corporate Admin — Create a time-bound offer and assign to stores.
//  Strictly iOS-native: Form + Section + native DatePicker, Picker, Toggle.
//  User Stories #10 (create offer, assign stores) & #17 (start/end dates).
//

import SwiftUI

// MARK: - CreateOfferView

struct CreateOfferView: View {

    @ObservedObject var service: OfferService
    @Environment(\.dismiss) private var dismiss

    // ── Form state ─────────────────────────────────────────────────
    @State private var name               = ""
    @State private var discountType       = DiscountType.percentage
    @State private var discountValue      = ""
    @State private var applicableTo       = "All Products"
    @State private var startDate          = Date()
    @State private var endDate            = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    @State private var selectedStoreIds   = Set<UUID>()
    @State private var performancePenalty = ""
    @State private var usageLimit         = ""
    @State private var isStackable        = false
    @State private var activationMethod   = "auto"
    @State private var couponCode         = ""
    @State private var storeSearchText    = ""

    // ── UX state ───────────────────────────────────────────────────
    @State private var showErrors    = false
    @State private var isSubmitting  = false
    @State private var showErrorAlert = false
    @State private var submitError: String? = nil

    private let scopeOptions = [
        "All Products", "Handbags", "Footwear",
        "Accessories", "Fragrances", "Ready-to-wear"
    ]

    // MARK: - Validation

    private var nameError: String? {
        name.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Promotion name is required." : nil
    }

    private var valueError: String? {
        guard let v = Double(discountValue) else { return "Enter a valid number." }
        if discountType == .percentage, !(1...100).contains(v) { return "Must be 1 – 100." }
        if discountType == .fixed, v <= 0 { return "Amount must be greater than 0." }
        return nil
    }

    private var dateError: String? {
        endDate <= startDate ? "End must be after start." : nil
    }

    private var storeError: String? {
        selectedStoreIds.isEmpty ? "Select at least one store." : nil
    }

    private var isValid: Bool {
        [nameError, valueError, dateError, storeError].allSatisfy { $0 == nil }
    }

    // Derived
    private var durationDays: Int {
        max(0, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
    }

    private var previewStatus: OfferStatus {
        if Date() < startDate { return .scheduled }
        if Date() > endDate   { return .expired }
        return .active
    }

    private var allSelected: Bool {
        selectedStoreIds.count == service.stores.count
    }
    
    private var filteredStores: [OfferStore] {
        if storeSearchText.isEmpty {
            return service.stores
        } else {
            return service.stores.filter { $0.name.localizedCaseInsensitiveContains(storeSearchText) || $0.city.localizedCaseInsensitiveContains(storeSearchText) }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {

                // ── 1. Promotion Details ───────────────────────────
                Section {
                    TextField("e.g. Diwali Collection Launch", text: $name)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)

                    if showErrors, let err = nameError {
                        inlineError(err)
                    }

                } header: {
                    sectionHeader("Promotion Name")
                }
                .listRowBackground(RSMSTheme.Colors.backgroundDeep)

                // ── 2. Discount ────────────────────────────────────
                Section {
                    Picker("Type", selection: $discountType) {
                        ForEach(DiscountType.allCases, id: \.self) { dt in
                            Text(dt.displayName).tag(dt)
                        }
                    }
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .tint(RSMSTheme.Colors.accentGold)

                    HStack {
                        Text(discountType == .percentage ? "Value (%)" : "Amount (₹)")
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        Spacer()
                        TextField(
                            discountType == .percentage ? "e.g. 15" : "e.g. 5000",
                            text: $discountValue
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .frame(maxWidth: 140)
                    }

                    if showErrors, let err = valueError {
                        inlineError(err)
                    }

                    Picker("Applicable To", selection: $applicableTo) {
                        ForEach(scopeOptions, id: \.self) { opt in
                            Text(opt).tag(opt)
                        }
                    }
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .tint(RSMSTheme.Colors.accentGold)

                } header: {
                    sectionHeader("Discount")
                }
                .listRowBackground(RSMSTheme.Colors.backgroundDeep)

                // ── 3. Offer Period ────────────────────────────────
                Section {
                    // Status preview
                    HStack {
                        Text("Preview Status")
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        Spacer()
                        OfferStatusPill(status: previewStatus)
                    }

                    DatePicker(
                        "Start",
                        selection: $startDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .tint(RSMSTheme.Colors.accentGold)

                    DatePicker(
                        "End",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .tint(RSMSTheme.Colors.accentGold)

                    if showErrors, let err = dateError {
                        inlineError(err)
                    }

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("Duration: \(durationDays) day\(durationDays == 1 ? "" : "s")")
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                    .font(.subheadline)

                } header: {
                    sectionHeader("Offer Period")
                } footer: {
                    Text("The discount activates automatically when the start date is reached and stops when the end date passes.")
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .listRowBackground(RSMSTheme.Colors.backgroundDeep)

                // ── 4. Store Assignment ────────────────────────────
                Section {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        TextField("Search stores by name or city...", text: $storeSearchText)
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    }
                    
                    // Select all toggle
                    Button {
                        withAnimation {
                            if allSelected {
                                selectedStoreIds.removeAll()
                            } else {
                                selectedStoreIds = Set(service.stores.map(\.id))
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: allSelected
                                  ? "checkmark.square.fill"
                                  : "square")
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                            Text(allSelected ? "Deselect All" : "Select All")
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)

                    if showErrors, let err = storeError {
                        inlineError(err)
                    }

                    ForEach(filteredStores) { store in
                        let isOn = selectedStoreIds.contains(store.id)
                        Button {
                            withAnimation {
                                if isOn {
                                    selectedStoreIds.remove(store.id)
                                } else {
                                    selectedStoreIds.insert(store.id)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: isOn
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .foregroundStyle(
                                        isOn
                                            ? RSMSTheme.Colors.accentGold
                                            : RSMSTheme.Colors.textTertiary
                                    )
                                    .font(.system(size: 20))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.name)
                                        .font(.body)
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                    Text(store.city)
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                } header: {
                    sectionHeader("Assign to Stores")
                } footer: {
                    Text("The discount only applies at checkout in the selected stores.")
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .listRowBackground(RSMSTheme.Colors.backgroundDeep)

                // ── 5. Configuration ───────────────────────────────
                Section {
                    Picker("Activation Method", selection: $activationMethod) {
                        Text("Auto Apply").tag("auto")
                        Text("Coupon Code").tag("coupon")
                    }
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .tint(RSMSTheme.Colors.accentGold)
                    
                    if activationMethod == "coupon" {
                        HStack {
                            Text("Coupon Code")
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Spacer()
                            TextField("e.g. DIWALI25", text: $couponCode)
                                .textInputAutocapitalization(.characters)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                    }
                    
                    Toggle("Stackable with other offers", isOn: $isStackable)
                        .tint(RSMSTheme.Colors.accentGold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    
                    HStack {
                        Text("Usage Limit per Customer")
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        Spacer()
                        TextField("e.g. 1", text: $usageLimit)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                            .frame(maxWidth: 80)
                    }
                } header: {
                    sectionHeader("Configuration")
                }
                .listRowBackground(RSMSTheme.Colors.backgroundDeep)

                // ── 6. Conditions (optional) ───────────────────────
                Section {
                    TextField(
                        "e.g. Void if basket < ₹5,000",
                        text: $performancePenalty,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)

                } header: {
                    sectionHeader("Performance Conditions (Optional)")
                }
                .listRowBackground(RSMSTheme.Colors.backgroundDeep)

            }
            .scrollContentBackground(.hidden)
            .background(RSMSTheme.Colors.backgroundPrimary)
            .navigationTitle("Create Promotion")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSubmitting {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                    } else {
                        Button("Create") {
                            submit()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            isValid
                                ? RSMSTheme.Colors.accentGold
                                : RSMSTheme.Colors.textTertiary
                        )
                    }
                }
            }
            .alert("Creation Failed", isPresented: $showErrorAlert) {
                Button("OK") { submitError = nil }
            } message: {
                Text(submitError ?? "An unknown error occurred. Please try again.")
            }
        }
        .colorScheme(.dark)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(RSMSTheme.Colors.accentGold)
            .textCase(nil)
    }

    @ViewBuilder
    private func inlineError(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.caption)
            .foregroundStyle(RSMSTheme.Colors.error)
            .listRowBackground(RSMSTheme.Colors.error.opacity(0.08))
    }

    // MARK: - Submit

    private func submit() {
        showErrors = true
        guard isValid else { return }

        let newOffer = Offer(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            discountType: discountType,
            discountValue: Double(discountValue) ?? 0,
            applicableTo: applicableTo == "All Products" ? nil : applicableTo,
            startDate: startDate,
            endDate: endDate,
            assignedStoreIds: Array(selectedStoreIds),
            performancePenalty: performancePenalty.isEmpty ? nil : performancePenalty,
            usageLimit: Int(usageLimit),
            isStackable: isStackable,
            activationMethod: activationMethod,
            couponCode: activationMethod == "coupon" ? (couponCode.isEmpty ? nil : couponCode) : nil,
            status: .scheduled
        )

        isSubmitting = true

        service.addOffer(newOffer) { success in
            isSubmitting = false
            if success {
                dismiss()
            } else {
                submitError = service.errorMessage ?? "Failed to create offer."
                showErrorAlert = true
            }
        }
    }
}
