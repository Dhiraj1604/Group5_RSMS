//
//  AddEditTaxView.swift
//  Group5_RSMS
//
//  Views/CorporateAdmin/Taxation — Add / Edit Tax Rule Modal
//  A luxury-themed form for creating or editing a category-based TaxRule.
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

    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    // MARK: - Init

    init(viewModel: TaxSettingsViewModel, existingRule: TaxRule? = nil) {
        self.viewModel = viewModel
        self.existingRule = existingRule

        _selectedCategory = State(initialValue: existingRule?.category ?? .other)
        _taxName = State(initialValue: existingRule?.name ?? "")
        _rateString = State(initialValue: existingRule.map {
            String(format: "%.3g", $0.rate * 100)
        } ?? "")
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

            VStack(spacing: 24) {
                // Category Selection
                categoryPickerSection
                
                // Name Field
                nameFieldSection
                
                // Rate Field
                rateFieldSection
                
                // Error Display
                if showValidationError {
                    errorDisplay
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(RSMSTheme.Colors.backgroundPrimary)
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .tint(RSMSTheme.Colors.accentGold)
                }
            }
        }
    }

    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Cancel Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }

            Spacer()

            Text(existingRule == nil ? "New Tax Rule" : "Edit Tax Rule")
                .font(.custom("HelveticaNeue-Bold", size: 18))
                .foregroundStyle(.white)

            Spacer()

            // Save Button
            Button {
                attemptSave()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Sections

    private var categoryPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRODUCT CATEGORY")
                .font(.custom("HelveticaNeue-Bold", size: 12))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                .tracking(1.0)
            
            Menu {
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
//                         Image(systemName: "xmark.circle.fill")
//                             .font(.system(size: 18))
//                             .foregroundColor(RSMSTheme.Colors.error)
//                     }
//                 }
//                 ToolbarItem(placement: .confirmationAction) {
//                     Button {
//                         attemptSave()
//                     } label: {
//                         if isSaving {
//                             ProgressView()
//                                 .tint(RSMSTheme.Colors.accentGold)
//                                 .scaleEffect(0.8)
//                         } else {
//                             Image(systemName: "checkmark.circle.fill")
//                                 .font(.system(size: 20, weight: .semibold))
//                             .foregroundColor(isSaveDisabled ? RSMSTheme.Colors.accentGold.opacity(0.4) : RSMSTheme.Colors.accentGold)
//                         }
                        Label(category.rawValue, systemImage: category.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedCategory.icon)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .font(.system(size: 20))
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCategory.rawValue)
                            .font(.custom("HelveticaNeue-Bold", size: 16))
                            .foregroundStyle(.white)
                        Text("Applies to all products in this category")
                            .font(.custom("HelveticaNeue", size: 11))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TAX NAME")
                .font(.custom("HelveticaNeue-Bold", size: 12))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                .tracking(1.0)
            
            HStack(spacing: 12) {
                Image(systemName: "doc.plaintext")
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                
                TextField("e.g. Luxury Goods Tax", text: $taxName)
                    .font(.custom("HelveticaNeue", size: 16))
                    .foregroundStyle(.white)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private var rateFieldSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TAX RATE (%)")
                .font(.custom("HelveticaNeue-Bold", size: 12))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                .tracking(1.0)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("%")
                        .font(.custom("HelveticaNeue-Bold", size: 18))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    
                    TextField("0", text: $rateString)
                        .keyboardType(.decimalPad)
                        .font(.custom("HelveticaNeue-Bold", size: 24))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                Text("Enter as a percentage. 20% VAT → enter 20. Stored internally as 0.20.")
                    .font(.custom("HelveticaNeue", size: 11))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
        }
    }

    private var errorDisplay: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(RSMSTheme.Colors.error)
            Text(validationMessage)
                .font(.custom("HelveticaNeue-Medium", size: 13))
                .foregroundColor(RSMSTheme.Colors.error)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
