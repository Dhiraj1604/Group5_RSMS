//
//  EditEmployeeView.swift
//  Group5_RSMS
//
//  Premium Edit Employee View - Native iPadOS style.
//  Enhanced with symbol-only toolbars and professional intelligence styling.
//

import SwiftUI

struct EditEmployeeView: View {
    let employee: Employee
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var role: String
    @State private var phone: String
    @State private var email: String
    @State private var salary: String
    @State private var joiningDate: Date
    @State private var isActive: Bool
    
    @State private var showRolePicker = false
    @State private var showDeleteConfirmation = false
    
    let roles = ["Manager", "Cashier", "Sales Associate", "Inventory Clerk", "Visual Merchandiser"]
    
    init(employee: Employee, boutiqueId: UUID, staffVM: StaffViewModel) {
        self.employee = employee
        self.boutiqueId = boutiqueId
        self.staffVM = staffVM
        
        _name = State(initialValue: employee.name)
        _role = State(initialValue: employee.role)
        _phone = State(initialValue: employee.phone ?? "")
        _email = State(initialValue: employee.email ?? "")
        _salary = State(initialValue: employee.salary != nil ? "\(Int(employee.salary!))" : "")
        _joiningDate = State(initialValue: employee.joiningDate ?? Date())
        _isActive = State(initialValue: employee.isActive ?? true)
    }
    
    var body: some View {
        NavigationStack {
            SwiftUI.Form {
                Section {
                    TextField("Full Name", text: $name)
                        .font(.headline)
                    TextField("Primary Contact", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Digital Correspondence", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Identity Intelligence")
                }
                
                Section {
                    Picker("Designated Role", selection: $role) {
                        ForEach(roles, id: \.self) { role in
                            Text(role).tag(role)
                        }
                    }
                    
                    TextField("Base Salary (₹)", text: $salary)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Association Date", selection: $joiningDate, displayedComponents: .date)
                } header: {
                    Text("Boutique Operational Role")
                }
                
                Section {
                    Toggle("Operational Status", isOn: $isActive)
                        .tint(.green)
                } footer: {
                    Text("Deactivating a specialist suspends their ability to process sales or manage inventory.")
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Permanently Remove Specialist")
                                .font(.custom("Helvetica", size: 11))
                                .fontWeight(.black)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Refine Specialist")
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
                    Button { saveChanges() } label: {
                        ZStack {
                            Circle().fill(name.isEmpty ? Color.secondary.opacity(0.1) : Color.accentColor).frame(width: 36, height: 36)
                            Image(systemName: "checkmark").font(.custom("Helvetica", size: 14)).fontWeight(.bold).foregroundColor(.white)
                        }
                    }
                    .disabled(name.isEmpty || role.isEmpty)
                }
            }
            .confirmationDialog("Remove Specialist", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteEmployee()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you certain you wish to remove \(employee.name)? This data cannot be recovered.")
            }
        }
    }
    
    private func saveChanges() {
        Task {
            let updatedEmployee = Employee(
                id: employee.id,
                boutiqueId: boutiqueId,
                name: name,
                email: email.isEmpty ? nil : email,
                phone: phone.isEmpty ? nil : phone,
                role: role,
                salary: Double(salary),
                joiningDate: joiningDate,
                isActive: isActive,
                createdAt: employee.createdAt
            )
            await staffVM.updateEmployee(updatedEmployee, boutiqueId: boutiqueId)
            dismiss()
        }
    }
    
    private func deleteEmployee() {
        Task {
            await staffVM.deleteEmployee(employee, boutiqueId: boutiqueId)
            dismiss()
        }
    }
}
