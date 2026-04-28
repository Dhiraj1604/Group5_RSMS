//
//  SetCommissionView.swift
//  Group5_RSMS
//
//  Premium Set Commission View - Native iPadOS style.
//  Enhanced with symbol-only toolbars and professional intelligence styling.
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
            SwiftUI.Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(employee.name)
                                .font(.headline.bold())
                            Text(employee.role.uppercased())
                                .font(.custom("Helvetica", size: 11))
                                .fontWeight(.black)
                                .tracking(1.5)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 52, height: 52)
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            Text(employee.name.prefix(1).uppercased())
                                .font(.headline.bold())
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 12)
                } header: {
                    Text("Staff Specialist")
                }
                
                Section {
                    HStack {
                        Text("Commission Rate")
                            .font(.headline)
                        Spacer()
                        TextField("0.0", text: $rateInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                            .frame(width: 80)
                        Text("%")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    
                    DatePicker("Effective Activation", selection: $effectiveFrom, displayedComponents: .date)
                } header: {
                    Text("Yield Configuration")
                } footer: {
                    if let error = commissionVM.errorMessage {
                        Text(error).foregroundColor(.red)
                    } else {
                        Text("Strategic commission adjustments impact future payout calculations.")
                    }
                }
            }
            .navigationTitle("Yield Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                            Image(systemName: "xmark").font(.custom("Helvetica", size: 14)).fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if commissionVM.isLoading {
                        ProgressView()
                    } else {
                        Button { saveRate() } label: {
                            ZStack {
                                Circle().fill(rateInput.isEmpty ? Color.secondary.opacity(0.1) : Color.accentColor).frame(width: 36, height: 36)
                                Image(systemName: "checkmark").font(.custom("Helvetica", size: 14)).fontWeight(.bold).foregroundColor(.white)
                            }
                        }
                        .disabled(rateInput.isEmpty)
                    }
                }
            }
        }
    }
    
    private func saveRate() {
        guard let rate = Double(rateInput), rate > 0 else { return }
        Task {
            await commissionVM.setCommissionRate(
                boutiqueId: boutiqueId,
                employeeId: employee.id,
                rate: rate,
                effectiveFrom: effectiveFrom,
                createdBy: UUID() 
            )
            if commissionVM.errorMessage == nil {
                dismiss()
            }
        }
    }
}
