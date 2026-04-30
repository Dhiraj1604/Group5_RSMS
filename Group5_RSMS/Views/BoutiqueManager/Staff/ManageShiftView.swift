//
//  ManageShiftView.swift
//  Group5_RSMS
//

import SwiftUI

// MARK: - Local UI Helpers
struct ShiftFormSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
            .padding(.leading, 8)
    }
}

struct ShiftFormDividerRow: View {
    var body: some View {
        Divider()
            .background(RSMSTheme.Colors.textSecondary.opacity(0.1))
            .padding(.horizontal, 16)
    }
}

struct ShiftFormPickerRow: View {
    let label: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Text(value)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Image(systemName: "chevron.up.down")
                        .font(.caption2)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

struct ManageShiftView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var shiftVM: ShiftViewModel
    let boutiqueId: UUID
    let employees: [Employee]
    
    // Optional existing shift to edit
    let existingShift: Shift?
    let selectedDateForNewShift: Date
    
    @State private var selectedEmployeeId: UUID?
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var errorMessage: String?
    @State private var showConflictAlert = false
    
    init(shiftVM: ShiftViewModel, boutiqueId: UUID, employees: [Employee], existingShift: Shift?, selectedDate: Date = Date()) {
        self.shiftVM = shiftVM
        self.boutiqueId = boutiqueId
        self.employees = employees
        self.existingShift = existingShift
        self.selectedDateForNewShift = selectedDate
        
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? Date()
        let defaultEnd = defaultStart.addingTimeInterval(3600 * 4)
        
        _startTime = State(initialValue: existingShift?.startTime ?? defaultStart)
        _endTime = State(initialValue: existingShift?.endTime ?? defaultEnd)
    }
    
    @State private var showEmployeePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Staff Member Section
                        VStack(alignment: .leading, spacing: 10) {
                            ShiftFormSectionHeader(title: "STAFF MEMBER")
                            
                            VStack(spacing: 0) {
                                ShiftFormPickerRow(
                                    label: "Employee",
                                    value: selectedEmployeeName
                                ) {
                                    if existingShift == nil {
                                        showEmployeePicker = true
                                    }
                                }
                            }
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(14)
                        }
                        
                        // Shift Timing Section
                        VStack(alignment: .leading, spacing: 10) {
                            ShiftFormSectionHeader(title: "SHIFT TIMING")
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Start Time")
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .accentColor(RSMSTheme.Colors.accentGold)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                
                                ShiftFormDividerRow()
                                
                                HStack {
                                    Text("End Time")
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .accentColor(RSMSTheme.Colors.accentGold)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(14)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                        }
                        
                        if let existing = existingShift {
                            Button(role: .destructive) {
                                Task {
                                    let success = await shiftVM.deleteShift(existing.id, boutiqueId: boutiqueId)
                                    if success { dismiss() }
                                }
                            } label: {
                                Text("Delete Shift")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(14)
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationTitle(existingShift == nil ? "Create Shift" : "Edit Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveShift() }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .disabled(selectedEmployeeId == nil || startTime >= endTime)
                }
            }
            .alert("Shift Conflict Detected", isPresented: $showConflictAlert) {
                Button("Save Anyway", role: .destructive) {
                    Task { await saveShiftForced() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This employee already has a shift scheduled during this time. Do you still want to save this shift?")
            }
            .sheet(isPresented: $showEmployeePicker) {
                NavigationStack {
                    List(employees) { employee in
                        Button {
                            selectedEmployeeId = employee.id
                            showEmployeePicker = false
                        } label: {
                            HStack {
                                Text(employee.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedEmployeeId == employee.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .navigationTitle("Select Employee")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { showEmployeePicker = false } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                if let shift = existingShift {
                    selectedEmployeeId = shift.employeeId
                } else if selectedEmployeeId == nil, let firstEmp = employees.first {
                    selectedEmployeeId = firstEmp.id
                }
            }
        }
    }
    
    private func saveShift() async {
        guard let empId = selectedEmployeeId else { return }

        // Check for conflict BEFORE saving — show a warning alert if found
        if shiftVM.hasConflict(for: empId, start: startTime, end: endTime, excludingShiftId: existingShift?.id) {
            showConflictAlert = true
            return
        }

        await saveShiftForced()
    }

    /// Saves the shift without conflict checking (used after user confirms the conflict alert)
    private func saveShiftForced() async {
        guard let empId = selectedEmployeeId else { return }

        let newShift = Shift(
            id: existingShift?.id ?? UUID(),
            boutiqueId: boutiqueId,
            employeeId: empId,
            startTime: startTime,
            endTime: endTime,
            createdAt: existingShift?.createdAt ?? Date()
        )

        let success: Bool
        if existingShift == nil {
            success = await shiftVM.createShift(newShift, boutiqueId: boutiqueId)
        } else {
            success = await shiftVM.updateShift(newShift, boutiqueId: boutiqueId)
        }

        if success {
            dismiss()
        } else {
            errorMessage = shiftVM.errorMessage
        }
    }
    
    private var selectedEmployeeName: String {
        if let id = selectedEmployeeId, let emp = employees.first(where: { $0.id == id }) {
            return emp.name
        }
        return "Select Employee"
    }
}
