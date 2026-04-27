//
//  CommissionPayoutView.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
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
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Header
                        VStack(spacing: 6) {
                            Text(employee.name)
                                .font(.title2)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Text("Create Payout")
                                .font(.body)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        .padding(.top)

                        // Period
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Payout Period")
                                .font(.caption)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("From")
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                        .font(.body)
                                    Spacer()
                                    DatePicker("", selection: $periodStart, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        
                                }
                                Divider().background(RSMSTheme.Colors.textSecondary.opacity(0.3))
                                HStack {
                                    Text("To")
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                        .font(.body)
                                    Spacer()
                                    DatePicker("", selection: $periodEnd, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        
                                }
                            }
                            .padding()
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)

                        // Total Sales Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Sales Amount (₹)")
                                .font(.caption)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                            HStack {
                                Text("₹")
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                                    .font(.headline)
                                TextField("e.g. 50000", text: $totalSalesInput)
                                    .keyboardType(.decimalPad)
                                    .font(.body)
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                            }
                            .padding()
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)

                        // Commission Preview
                        VStack(spacing: 12) {
                            HStack {
                                Text("Commission Rate")
                                    .font(.body)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Spacer()
                                Text("\(commissionRate, specifier: "%.1f")%")
                                    .font(.headline)
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                            }
                            Divider().background(RSMSTheme.Colors.textSecondary.opacity(0.3))
                            HStack {
                                Text("Commission Amount")
                                    .font(.body)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Spacer()
                                Text("₹\(commissionAmount, specifier: "%.2f")")
                                    .font(.title2)
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                            }
                        }
                        .padding()
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(12)
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

                        // Create Button
                        Button {
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
                        } label: {
                            Group {
                                if commissionVM.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Create Payout")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(commissionRate == 0 ? RSMSTheme.Colors.accentGold.opacity(0.4) : RSMSTheme.Colors.accentGold)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .disabled(totalSalesInput.isEmpty || commissionRate == 0 || commissionVM.isLoading)
                    }
                }
            }
            .navigationTitle("Payout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
    }
}
