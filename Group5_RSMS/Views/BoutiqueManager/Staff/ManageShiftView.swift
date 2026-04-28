//
//  ManageShiftView.swift
//  Group5_RSMS
//

import SwiftUI

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
                    VStack(spacing: 24) {
                        // Staff Member Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Staff Member")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            
                            DropdownRow(
                                label: "Employee",
                                value: selectedEmployeeName
                            ) {
                                if existingShift == nil {
                                    showEmployeePicker = true
                                }
                            }
                        }
                        
                        // Shift Timing Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Shift Timing")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            
                            VStack(spacing: 12) {
                                DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                    
                                
                                DatePicker("End Time", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                                    
                            }
                            .padding()
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(12)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    .cornerRadius(12)
                            }
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(existingShift == nil ? "Create Shift" : "Edit Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveShift() }
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
                            Button("Cancel") { showEmployeePicker = false }
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
