//
//  AddEditTaxView.swift
//  Group5_RSMS
//
//  Views/CorporateAdmin/Taxation — Add / Edit Tax Rule Modal
//  A luxury-themed form for creating or editing a TaxRule.
//  The store picker only shows boutiques registered via Store Registration (Task 1).
//

import SwiftUI

@available(iOS 16.0, *)
struct AddEditTaxView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Dependencies

    @ObservedObject var viewModel: TaxSettingsViewModel

    /// If editing an existing rule, pass it in. Nil = adding a new rule.
    var existingRule: TaxRule?

    // MARK: - Form State

    @State private var selectedStoreId: UUID?
    @State private var taxName: String
    @State private var rateString: String
    @State private var isInclusive: Bool

    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    // MARK: - Computed

    /// Save is disabled unless a boutique is selected AND a valid rate is entered.
    private var isSaveDisabled: Bool {
        let hasStore = selectedStoreId != nil
        let hasName = !taxName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRate = Double(rateString).map { $0 > 0 && $0 <= 100 } ?? false
        return !(hasStore && hasName && hasRate)
    }

    // MARK: - Init

    init(viewModel: TaxSettingsViewModel, existingRule: TaxRule? = nil) {
        self.viewModel = viewModel
        self.existingRule = existingRule

        _selectedStoreId = State(initialValue: existingRule?.storeId)
        _taxName = State(initialValue: existingRule?.name ?? "")
        _rateString = State(initialValue: existingRule.map {
            String(format: "%.3g", $0.rate * 100)
        } ?? "")
        _isInclusive = State(initialValue: existingRule?.isInclusive ?? true)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {

                        headerIcon

                        // Boutique Picker (Task 3)
                        formCard {
                            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                                formLabel("Select Boutique")

                                if viewModel.availableStores.isEmpty {
                                    // No stores registered yet
                                    HStack(spacing: RSMSTheme.Spacing.sm) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.warning)

                                        Text("No boutiques registered. Please add a store first.")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(RSMSTheme.Colors.warning)
                                    }
                                    .padding(RSMSTheme.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                            .fill(RSMSTheme.Colors.warning.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                                    .stroke(RSMSTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                } else {
                                    Menu {
                                        ForEach(viewModel.availableStores) { store in
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedStoreId = store.id
                                                }
                                            } label: {
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text("\(store.city), \(store.country)")
                                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                        Text(store.name)
                                                            .font(.caption2)
                                                    }
                                                    Spacer()
                                                    if store.id == selectedStoreId {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "storefront.fill")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(RSMSTheme.Colors.accentGold)

                                            if let storeId = selectedStoreId,
                                               let store = viewModel.availableStores.first(where: { $0.id == storeId }) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("\(store.city), \(store.country)")
                                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                        .foregroundColor(RSMSTheme.Colors.textPrimary)

                                                    Text(store.name)
                                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                                }
                                            } else {
                                                Text("Choose a boutique…")
                                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(RSMSTheme.Colors.accentGoldDark)
                                        }
                                        .padding(RSMSTheme.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                                .fill(RSMSTheme.Colors.backgroundElevated)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                                        .stroke(
                                                            selectedStoreId == nil
                                                                ? RSMSTheme.Colors.accentGoldDark.opacity(0.15)
                                                                : RSMSTheme.Colors.accentGold.opacity(0.4),
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        // Tax Name
                        formCard {
                            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                                formLabel("Tax Name")

                                HStack(spacing: RSMSTheme.Spacing.sm) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(RSMSTheme.Colors.accentGold)

                                    TextField("e.g., VAT", text: $taxName)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                        .autocorrectionDisabled()
                                }
                                .padding(RSMSTheme.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                        .fill(RSMSTheme.Colors.backgroundElevated)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                                .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }

                        // Rate
                        formCard {
                            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                                formLabel("Tax Rate (%)")

                                HStack(spacing: RSMSTheme.Spacing.sm) {
                                    Image(systemName: "percent")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(RSMSTheme.Colors.accentGold)

                                    TextField("e.g., 8.875", text: $rateString)
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundColor(RSMSTheme.Colors.accentGoldLight)
                                        .keyboardType(.decimalPad)

                                    Spacer()

                                    // Live preview
                                    if let val = Double(rateString), val > 0 {
                                        Text(String(format: "%.4f", val / 100))
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                            .padding(.horizontal, RSMSTheme.Spacing.sm)
                                            .padding(.vertical, RSMSTheme.Spacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(RSMSTheme.Colors.backgroundPrimary.opacity(0.6))
                                            )
                                    }
                                }
                                .padding(RSMSTheme.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                        .fill(RSMSTheme.Colors.backgroundElevated)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                                .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 1)
                                        )
                                )

                                Text("Enter as a percentage. 20% VAT → enter 20. Stored internally as 0.20.")
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                                    .padding(.top, RSMSTheme.Spacing.xs)
                            }
                        }

                        // Inclusive Toggle
                        formCard {
                            HStack {
                                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                                    formLabel("Price Includes Tax")

                                    Text(
                                        isInclusive
                                            ? "The listed price already contains the tax amount."
                                            : "Tax will be added on top of the listed price."
                                    )
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: $isInclusive)
                                    .labelsHidden()
                                    .tint(RSMSTheme.Colors.accentGold)
                            }
                        }

                        // Validation Error
                        if showValidationError {
                            HStack(spacing: RSMSTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(RSMSTheme.Colors.error)

                                Text(validationMessage)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(RSMSTheme.Colors.error)
                            }
                            .padding(RSMSTheme.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                    .fill(RSMSTheme.Colors.error.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                                            .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Save Button
                        Button {
                            attemptSave()
                        } label: {
                            HStack(spacing: RSMSTheme.Spacing.sm) {
                                if isSaving {
                                    ProgressView()
                                        .tint(RSMSTheme.Colors.backgroundPrimary)
                                        .padding(.trailing, 4)
                                } else {
                                    Image(systemName: existingRule == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                }

                                Text(isSaving ? "Saving..." : (existingRule == nil ? "Add Tax Rule" : "Update Tax Rule"))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                        }
                        .buttonStyle(GoldButtonStyle())
                        .opacity((isSaveDisabled || isSaving) ? 0.45 : 1.0)
                        .disabled(isSaveDisabled || isSaving)
                        .padding(.top, RSMSTheme.Spacing.sm)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.lg)
                    .padding(.top, RSMSTheme.Spacing.xl)
                    .padding(.bottom, RSMSTheme.Spacing.xxxl)
                }
            }
            .navigationTitle(existingRule == nil ? "New Tax Rule" : "Edit Tax Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                .frame(width: 72, height: 72)

            Circle()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.06))
                .frame(width: 56, height: 56)

            Image(systemName: existingRule == nil ? "plus.rectangle.on.folder" : "pencil.and.list.clipboard")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.accentGold)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
            content()
        }
        .cardStyle()
    }

    private func formLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(RSMSTheme.Colors.textPrimary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    // MARK: - Actions

    private func attemptSave() {
        // Validate
        guard let storeId = selectedStoreId else {
            showError("Please select a boutique.")
            return
        }

        let trimmedName = taxName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showError("Tax name cannot be empty.")
            return
        }

        guard let ratePercent = Double(rateString), ratePercent > 0, ratePercent <= 100 else {
            showError("Enter a valid rate between 0 and 100.")
            return
        }

        // Convert to decimal (e.g. 20 → 0.20)
        let rateDecimal = ratePercent / 100.0

        let rule = TaxRule(
            id: existingRule?.id ?? UUID(),
            name: trimmedName,
            rate: rateDecimal,
            isInclusive: isInclusive,
            storeId: storeId
        )

        isSaving = true
        Task {
            let success = await viewModel.saveRule(rule)
            isSaving = false
            if success {
                dismiss()
            } else {
                showError("Failed to save rule: \(viewModel.errorMessage ?? "Unknown error")")
            }
        }
    }

    private func showError(_ msg: String) {
        validationMessage = msg
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showValidationError = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showValidationError = false }
        }
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview("Add New") {
    AddEditTaxView(viewModel: TaxSettingsViewModel())
        .preferredColorScheme(.dark)
}

@available(iOS 16.0, *)
#Preview("Edit Existing") {
    let vm = TaxSettingsViewModel()
    AddEditTaxView(viewModel: vm, existingRule: vm.taxRules.first)
        .preferredColorScheme(.dark)
}
