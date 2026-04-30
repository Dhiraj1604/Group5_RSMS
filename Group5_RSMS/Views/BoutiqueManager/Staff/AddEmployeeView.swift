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
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - UI Helpers
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - AddEmployeeView Helpers

struct StaffFormRow<Content: View>: View {
    let label: String
    let content: () -> Content
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .font(.system(size: 16))
            Spacer()
            content()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AddEmployeeView
struct AddEmployeeView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    @ObservedObject var shiftVM: ShiftViewModel
    @ObservedObject var vm: AddEmployeeViewModel
    let employeeToEdit: Employee?

    @Environment(\.dismiss) private var dismiss

    @State private var showRolePicker = false
    @State private var showCountryCodePicker = false
    @State private var showOffDayPicker = false
    
    init(boutiqueId: UUID, staffVM: StaffViewModel, shiftVM: ShiftViewModel, vm: AddEmployeeViewModel, employeeToEdit: Employee? = nil) {
        self.boutiqueId = boutiqueId
        self.staffVM = staffVM
        self.shiftVM = shiftVM
        self.vm = vm
        self.employeeToEdit = employeeToEdit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                List {
                    // Header Avatar Section
                    Section {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                                    .frame(width: 90, height: 90)
                                Text(vm.name.prefix(1).uppercased().isEmpty ? "?" : String(vm.name.prefix(1).uppercased()))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    // Personal Details
                    Section("PERSONAL DETAILS") {
                        StaffFormRow(label: "Full Name") {
                            TextField("", text: $vm.name)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        
                        HStack(spacing: 0) {
                            Text("Phone")
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                .font(.system(size: 16))
                            Spacer()
                            Button {
                                showCountryCodePicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(vm.countryCode)
                                        .foregroundColor(RSMSTheme.Colors.accentGold)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(RSMSTheme.Colors.accentGold)
                                }
                            }
                            .padding(.trailing, 8)
                            
                            TextField("", text: $vm.phone)
                                .keyboardType(.phonePad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                                .frame(width: 140)
                        }
                        .padding(.vertical, 4)

                        StaffFormRow(label: "Email") {
                            TextField("", text: $vm.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                    }
                    .listRowBackground(RSMSTheme.Colors.backgroundElevated)

                    // Employment Details
                    Section("EMPLOYMENT DETAILS") {
                        Button { showRolePicker = true } label: {
                            StaffFormRow(label: "Role") {
                                HStack(spacing: 4) {
                                    Text(vm.role)
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                                }
                            }
                        }
                        
                        StaffFormRow(label: "Salary") {
                            HStack(spacing: 4) {
                                Text("₹")
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                                TextField("0", text: $vm.salary)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                        }

                        HStack {
                            Text("Joining Date")
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                .font(.system(size: 16))
                            Spacer()
                            DatePicker("", selection: $vm.joiningDate, displayedComponents: .date)
                                .labelsHidden()
                                .accentColor(RSMSTheme.Colors.accentGold)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(RSMSTheme.Colors.backgroundElevated)

                    // Roster Management
                    Section("ROSTER MANAGEMENT") {
                        HStack {
                            Text("Shift Start")
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                .font(.system(size: 16))
                            Spacer()
                            DatePicker("", selection: $vm.shiftStartTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "en_GB"))
                                .accentColor(RSMSTheme.Colors.accentGold)
                        }
                        .padding(.vertical, 4)

                        HStack {
                            Text("Shift End")
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                .font(.system(size: 16))
                            Spacer()
                            DatePicker("", selection: $vm.shiftEndTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "en_GB"))
                                .accentColor(RSMSTheme.Colors.accentGold)
                        }
                        .padding(.vertical, 4)

                        Button { showOffDayPicker = true } label: {
                            StaffFormRow(label: "Weekly Off") {
                                HStack(spacing: 4) {
                                    Text(vm.weeklyOff)
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                    .listRowBackground(RSMSTheme.Colors.backgroundElevated)

                    if let error = staffVM.errorMessage {
                        Section {
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(employeeToEdit == nil ? "Add Employee" : "Edit Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if staffVM.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            guard !vm.name.isEmpty else { return }
                            Task {
                                let employee = vm.createEmployee(boutiqueId: boutiqueId, existingId: employeeToEdit?.id)
                                let empId = employee.id
                                
                                // 1. Save Employee details
                                if employeeToEdit == nil {
                                    await staffVM.addEmployee(employee, boutiqueId: boutiqueId)
                                } else {
                                    await staffVM.updateEmployee(employee, boutiqueId: boutiqueId)
                                }
                                
                                // 2. Create/Update Shift for today (so it reflects in Info)
                                if staffVM.errorMessage == nil {
                                    let calendar = Calendar.current
                                    let today = Date()
                                    
                                    // Construct shift start/end for today
                                    let startComp = calendar.dateComponents([.hour, .minute], from: vm.shiftStartTime)
                                    let endComp = calendar.dateComponents([.hour, .minute], from: vm.shiftEndTime)
                                    
                                    if let startDate = calendar.date(bySettingHour: startComp.hour ?? 9, minute: startComp.minute ?? 0, second: 0, of: today),
                                       var endDate = calendar.date(bySettingHour: endComp.hour ?? 18, minute: endComp.minute ?? 0, second: 0, of: today) {
                                        
                                        // Handle overnight shifts
                                        if endDate <= startDate {
                                            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                                        }
                                        
                                        // Check if a shift already exists for this employee today
                                        let existingShift = shiftVM.shifts.first { 
                                            $0.employeeId == empId && calendar.isDate($0.startTime, inSameDayAs: today) 
                                        }
                                        
                                        if let existing = existingShift {
                                            var updated = existing
                                            updated.startTime = startDate
                                            updated.endTime = endDate
                                            _ = await shiftVM.updateShift(updated, boutiqueId: boutiqueId)
                                        } else {
                                            let newShift = Shift(
                                                id: UUID(),
                                                boutiqueId: boutiqueId,
                                                employeeId: empId,
                                                startTime: startDate,
                                                endTime: endDate,
                                                createdAt: Date()
                                            )
                                            _ = await shiftVM.createShift(newShift, boutiqueId: boutiqueId)
                                        }
                                    }
                                    
                                    dismiss()
                                }
                            }
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }
                        .disabled(vm.name.isEmpty)
                    }
                }
            }
            .onAppear {
                if let employee = employeeToEdit {
                    vm.setupForEditing(employee)
                    
                    // Also find actual shift from shifts table to pre-populate timing
                    if let lastShift = shiftVM.shifts
                        .filter({ $0.employeeId == employee.id })
                        .sorted(by: { $0.startTime > $1.startTime })
                        .first {
                        vm.shiftStartTime = lastShift.startTime
                        vm.shiftEndTime = lastShift.endTime
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
            // Off-day picker sheet
            .sheet(isPresented: $showOffDayPicker) {
                OptionPickerSheet(
                    title: "Weekly Off",
                    options: vm.days,
                    displayText: { $0 },
                    selected: $vm.weeklyOff,
                    isPresented: $showOffDayPicker
                )
            }
        }
    }
}
