//
//  AddEmployeeView.swift
//  Group5_RSMS
//

import SwiftUI

// MARK: - Custom Dropdown Sheet (works inside any .sheet presentation)
struct OptionPickerSheet<T: Hashable>: View {
    let title: String
    let options: [T]
    let displayText: (T) -> String
    @Binding var selected: T
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            List(options, id: \.self) { option in
                Button {
                    selected = option
                    isPresented = false
                } label: {
                    HStack {
                        Text(displayText(option))
                            .foregroundColor(.primary)
                        Spacer()
                        if option == selected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Reusable Dropdown Row
struct DropdownRow: View {
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .font(.subheadline)
                Spacer()
                Text(value)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .font(.subheadline)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            .padding()
            .background(RSMSTheme.Colors.backgroundDeep)
            .cornerRadius(12)
        }
    }
}

// MARK: - AddEmployeeView
struct AddEmployeeView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    @ObservedObject var vm: AddEmployeeViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var showRolePicker = false
    @State private var showCountryCodePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Avatar
                        ZStack {
                            Circle()
                                .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(vm.name.prefix(1).uppercased().isEmpty ? "?" : String(vm.name.prefix(1).uppercased()))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }
                        .padding(.top, 16)

                        // Personal Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Details")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                            TextField("Full Name *", text: $vm.name)
                                .padding()
                                .background(RSMSTheme.Colors.backgroundDeep)
                                .cornerRadius(12)

                            // Phone with country code
                            HStack(spacing: 8) {
                                // Country code tap button
                                Button {
                                    showCountryCodePicker = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(vm.countryCode)
                                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                                            .font(.subheadline)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 10)
                                    .background(RSMSTheme.Colors.backgroundDeep)
                                    .cornerRadius(12)
                                }

                                TextField("Phone Number", text: $vm.phone)
                                    .keyboardType(.phonePad)
                                    .padding()
                                    .background(RSMSTheme.Colors.backgroundDeep)
                                    .cornerRadius(12)
                            }

                            TextField("Email", text: $vm.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(RSMSTheme.Colors.backgroundDeep)
                                .cornerRadius(12)
                        }

                        // Employment Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Employment Details")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                            DropdownRow(label: "Role *", value: vm.role) {
                                showRolePicker = true
                            }

                            TextField("Salary (₹)", text: $vm.salary)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(RSMSTheme.Colors.backgroundDeep)
                                .cornerRadius(12)

                            DatePicker("Joining Date", selection: $vm.joiningDate, displayedComponents: .date)
                                .padding()
                                .background(RSMSTheme.Colors.backgroundDeep)
                                .cornerRadius(12)
                                .colorScheme(.dark)
                        }

                        if let error = staffVM.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if staffVM.isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            guard !vm.name.isEmpty else { return }
                            Task {
                                let employee = vm.createEmployee(boutiqueId: boutiqueId)
                                await staffVM.addEmployee(employee, boutiqueId: boutiqueId)
                                if staffVM.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        }
                        .disabled(vm.name.isEmpty)
                    }
                }
            }
            // Role picker sheet — presented independently from parent sheet
            .sheet(isPresented: $showRolePicker) {
                OptionPickerSheet(
                    title: "Select Role",
                    options: vm.roles,
                    displayText: { $0 },
                    selected: $vm.role,
                    isPresented: $showRolePicker
                )
            }
            // Country code picker sheet
            .sheet(isPresented: $showCountryCodePicker) {
                OptionPickerSheet(
                    title: "Country Code",
                    options: vm.countryCodes,
                    displayText: { $0 },
                    selected: $vm.countryCode,
                    isPresented: $showCountryCodePicker
                )
            }
        }
    }
}
