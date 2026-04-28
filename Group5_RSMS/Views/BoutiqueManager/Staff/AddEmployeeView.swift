//
//  AddEmployeeView.swift
//  Group5_RSMS
//
//  Premium Add Employee View - Native iPadOS style.
//  Enhanced with symbol-only toolbars and professional intelligence styling.
//

import SwiftUI

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var staffVM: StaffViewModel
    @ObservedObject var vm: AddEmployeeViewModel
    let boutiqueId: UUID
    
    var body: some View {
        NavigationStack {
            SwiftUI.Form {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .font(.custom("Helvetica", size: 11))
                                .fontWeight(.black)
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            Image(systemName: "person.fill.badge.plus")
                                .font(.custom("Helvetica", size: 40))
                                .foregroundColor(.accentColor)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Profile Visual")
                }
                
                Section {
                    TextField("Full Name", text: $vm.name)
                        .font(.headline)
                    
                    HStack {
                        Picker("Code", selection: $vm.countryCode) {
                            ForEach(vm.countryCodes, id: \.self) { code in
                                Text(code).tag(code)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                        
                        TextField("Primary Contact", text: $vm.phone)
                            .keyboardType(.phonePad)
                    }
                    
                    TextField("Digital Correspondence", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Specialist Intelligence")
                }
                
                Section {
                    Picker("Functional Role", selection: $vm.role) {
                        ForEach(vm.roles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    
                    TextField("Base Salary (₹)", text: $vm.salary)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Association Date", selection: $vm.joiningDate, displayedComponents: .date)
                } header: {
                    Text("Boutique Role & Compensation")
                }
            }
            .navigationTitle("New Specialist")
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
                    Button {
                        saveEmployee()
                    } label: {
                        ZStack {
                            Circle().fill(vm.name.isEmpty ? Color.secondary.opacity(0.1) : Color.accentColor).frame(width: 36, height: 36)
                            Image(systemName: "checkmark").font(.custom("Helvetica", size: 14)).fontWeight(.bold).foregroundColor(.white)
                        }
                    }
                    .disabled(vm.name.isEmpty || vm.role.isEmpty)
                }
            }
        }
    }
    
    private func saveEmployee() {
        let newEmployee = vm.createEmployee(boutiqueId: boutiqueId)
        Task {
            await staffVM.addEmployee(newEmployee, boutiqueId: boutiqueId)
            dismiss()
        }
    }
}
