//
//  CommissionPayoutView.swift
//  Group5_RSMS
//
//  Premium Commission Payout View - Native iPadOS style.
//

import SwiftUI

struct CommissionPayoutView: View {
    let employee: Employee
    let boutiqueId: UUID
    @ObservedObject var commissionVM: CommissionViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var totalSalesInput: String = ""
    @State private var periodStart: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var periodEnd: Date = Date()

    var commissionRate: Double {
        commissionVM.currentRate(for: employee.id)?.ratePercentage ?? 0.0
    }

    var commissionAmount: Double {
        ((Double(totalSalesInput) ?? 0.0) * commissionRate) / 100.0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(employee.name)
                                .font(.headline)
                            Text(employee.role)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Text(employee.name.prefix(1).uppercased())
                                .font(.headline.bold())
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Staff Member")
                }
                
                Section {
                    DatePicker("From", selection: $periodStart, displayedComponents: .date)
                    DatePicker("To", selection: $periodEnd, in: periodStart..., displayedComponents: .date)
                } header: {
                    Text("Payout Period")
                }
                
                Section {
                    HStack {
                        Text("Total Sales")
                        Spacer()
                        TextField("0", text: $totalSalesInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("₹")
                            .foregroundColor(.secondary)
                            .bold()
                    }
                    
                    HStack {
                        Text("Commission Rate")
                        Spacer()
                        Text("\(commissionRate, specifier: "%.1f")%")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Commission Amount")
                            .bold()
                        Spacer()
                        Text("₹\(commissionAmount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                } header: {
                    Text("Calculation")
                } footer: {
                    if let error = commissionVM.errorMessage {
                        Text(error).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Create Payout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if commissionVM.isLoading {
                        ProgressView()
                    } else {
                        Button("Create") {
                            createPayout()
                        }
                        .bold()
                        .disabled(totalSalesInput.isEmpty || commissionRate == 0)
                    }
                }
            }
        }
    }
    
    private func createPayout() {
        guard let totalSales = Double(totalSalesInput), totalSales > 0 else { return }
        Task {
            await commissionVM.createPayout(
                boutiqueId: boutiqueId,
                employeeId: employee.id,
                periodStart: periodStart,
                periodEnd: periodEnd,
                totalSales: totalSales,
                commissionRate: commissionRate
            )
            if commissionVM.errorMessage == nil {
                dismiss()
            }
        }
    }
}
