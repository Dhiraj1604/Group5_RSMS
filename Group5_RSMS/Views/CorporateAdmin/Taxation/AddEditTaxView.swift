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

    @State private var selectedCategory: ProductCategory
    @State private var taxName: String
    @State private var rateString: String
    @State private var isInclusive: Bool

    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    // MARK: - Computed

    /// Save is disabled unless a category is selected AND a valid rate is entered.
    private var isSaveDisabled: Bool {
        let hasName = !taxName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRate = Double(rateString).map { $0 > 0 && $0 <= 100 } ?? false
        return !(hasName && hasRate)
    }

    // MARK: - Init

    init(viewModel: TaxSettingsViewModel, existingRule: TaxRule? = nil) {
        self.viewModel = viewModel
        self.existingRule = existingRule

        _selectedCategory = State(initialValue: existingRule?.category ?? .other)
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

                        // Category Picker
                        formCard {
                            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                                formLabel("Product Category")

                                Menu {
                                    ForEach(ProductCategory.allCases) { category in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCategory = category
                                            }
                                        } label: {
                                            HStack {
                                                Label(category.rawValue, systemImage: category.icon)
                                                Spacer()
                                                if category == selectedCategory {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedCategory.icon)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.accentGold)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(selectedCategory.rawValue)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                                            Text("Applies to all products in this category")
                                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                                .foregroundColor(RSMSTheme.Colors.textSecondary)
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
                                                        RSMSTheme.Colors.accentGold.opacity(0.4),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
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

                        // Active / Inactive — only shown when editing an existing rule
                        if let rule = existingRule {
                            let isActive = viewModel.activeRuleId == rule.id
                            formCard {
                                HStack(spacing: RSMSTheme.Spacing.md) {
                                    // Status icon
                                    ZStack {
                                        Circle()
                                            .fill(isActive
                                                  ? RSMSTheme.Colors.accentGold.opacity(0.15)
                                                  : Color.white.opacity(0.05))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: isActive ? "bolt.fill" : "bolt.slash")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(isActive ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textTertiary)
                                    }

                                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                                        formLabel(isActive ? "Active" : "Inactive")
                                        Text(isActive
                                             ? "This rule is currently applied to transactions."
                                             : "This rule is not applied. Tap to activate.")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    }

                                    Spacer()

                                    // Pill toggle button
                                    Button {
                                        if isActive {
                                            viewModel.activeRuleId = nil
                                        } else {
                                            viewModel.setActiveRule(rule)
                                        }
                                    } label: {
                                        Text(isActive ? "Deactivate" : "Activate")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .tracking(0.5)
                                            .foregroundColor(isActive ? .black : RSMSTheme.Colors.accentGold)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(
                                                isActive
                                                    ? RSMSTheme.Colors.accentGold
                                                    : RSMSTheme.Colors.accentGold.opacity(0.12)
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(RSMSTheme.Colors.accentGold.opacity(isActive ? 0 : 0.4), lineWidth: 1)
                                            )
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: isActive)
                                }
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
                            .foregroundColor(RSMSTheme.Colors.error)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        attemptSave()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(RSMSTheme.Colors.accentGold)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSaveDisabled ? RSMSTheme.Colors.accentGold.opacity(0.4) : RSMSTheme.Colors.accentGold)
                        }
                    }
                    .disabled(isSaveDisabled || isSaving)
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
            category: selectedCategory
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
        withAnimation { showValidationError = true }
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
