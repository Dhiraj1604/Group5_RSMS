//
//  SetCommissionView.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
//

import SwiftUI

struct SetCommissionView: View {
    let employee: Employee
    let boutiqueId: UUID
    @ObservedObject var commissionVM: CommissionViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var rateInput: String = ""
    @State private var effectiveFrom: Date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 6) {
                        Text(employee.name)
                            .font(.title2)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        Text("Set Commission Rate")
                            .font(.body)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                    .padding(.top)

                    // Rate Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Commission Rate (%)")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        HStack {
                            TextField("e.g. 10.5", text: $rateInput)
                                .keyboardType(.decimalPad)
                                .font(.body)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Text("%")
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                                .font(.headline)
                        }
                        .padding()
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Effective From
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effective From")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        DatePicker("", selection: $effectiveFrom, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            
                            .padding()
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // Error / Success
                    if let error = commissionVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    if let success = commissionVM.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Save Button
                    Button {
                        guard let rate = Double(rateInput), rate > 0 else { return }
                        Task {
                            await commissionVM.setCommissionRate(
                                boutiqueId: boutiqueId,
                                employeeId: employee.id,
                                rate: rate,
                                effectiveFrom: effectiveFrom,
                                createdBy: UUID() // replace with session manager id
                            )
                            if commissionVM.errorMessage == nil {
                                dismiss()
                            }
                        }
                    } label: {
                        Group {
                            if commissionVM.isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text("Save Rate")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.Colors.accentGold)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(rateInput.isEmpty || commissionVM.isLoading)
                }
            }
            .navigationTitle("Commission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
    }
}
