//
//  AddEmployeeView.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
//

import SwiftUI

struct AddEmployeeView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var role: String = "Sales Associate"
    @State private var salary: String = ""
    @State private var joiningDate: Date = Date()

    let roles = ["Sales Associate", "Store Supervisor", "Cashier", "Visual Merchandiser", "Alteration Tailor"]

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Avatar Preview
                        ZStack {
                            Circle()
                                .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(name.prefix(1).uppercased().isEmpty ? "?" : String(name.prefix(1).uppercased()))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }
                        .padding(.top)

                        // MARK: - Form Fields
                        VStack(spacing: 16) {

                            // Name
                            FormField(title: "Full Name *", placeholder: "e.g. Priya Sharma", text: $name)

                            // Role Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Role *")
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Menu {
                                    ForEach(roles, id: \.self) { r in
                                        Button(r) { role = r }
                                    }
                                } label: {
                                    HStack {
                                        Text(role)
                                            .font(.body)
                                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(RSMSTheme.Colors.backgroundDeep)
                                    .cornerRadius(10)
                                }
                            }

                            // Phone
                            FormField(title: "Phone", placeholder: "e.g. 9876543210", text: $phone, keyboardType: .phonePad)

                            // Email
                            FormField(title: "Email", placeholder: "e.g. priya@boutique.com", text: $email, keyboardType: .emailAddress)

                            // Salary
                            FormField(title: "Salary (₹)", placeholder: "e.g. 25000", text: $salary, keyboardType: .decimalPad)

                            // Joining Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Joining Date")
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                DatePicker("", selection: $joiningDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .padding()
                                    .background(RSMSTheme.Colors.backgroundDeep)
                                    .cornerRadius(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)

                        // MARK: - Error
                        if let error = staffVM.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(RSMSTheme.Colors.error)
                                .padding(.horizontal)
                        }

                        // MARK: - Save Button
                        Button {
                            guard !name.isEmpty else { return }
                            Task {
                                let employee = Employee(
                                    id: UUID(),
                                    boutiqueId: boutiqueId,
                                    name: name,
                                    email: email.isEmpty ? nil : email,
                                    phone: phone.isEmpty ? nil : phone,
                                    role: role,
                                    salary: Double(salary),
                                    joiningDate: joiningDate,
                                    isActive: true,
                                    createdAt: Date()
                                )
                                await staffVM.addEmployee(employee, boutiqueId: boutiqueId)
                                if staffVM.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            Group {
                                if staffVM.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text("Add Employee")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(name.isEmpty ? RSMSTheme.Colors.accentGold.opacity(0.4) : RSMSTheme.Colors.accentGold)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .disabled(name.isEmpty || staffVM.isLoading)
                    }
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
    }
}

// MARK: - Reusable Form Field
struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(.body)
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .padding()
                .background(RSMSTheme.Colors.backgroundDeep)
                .cornerRadius(10)
        }
    }
}
