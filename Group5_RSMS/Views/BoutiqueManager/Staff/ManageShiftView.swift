//
//  ManageShiftView.swift
//  Group5_RSMS
//
//  Premium Manage Shift View - Native iPadOS style.
//  Enhanced with symbol-only toolbars and professional intelligence styling.
//

import SwiftUI

struct ManageShiftView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var shiftVM: ShiftViewModel
    let boutiqueId: UUID
    let employees: [Employee]
    
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

    var body: some View {
        NavigationStack {
            SwiftUI.Form {
                Section {
                    Picker("Select Specialist", selection: $selectedEmployeeId) {
                        if selectedEmployeeId == nil {
                            Text("Unassigned").tag(UUID?.none)
                        }
                        ForEach(employees) { employee in
                            Text(employee.name).tag(UUID?.some(employee.id))
                        }
                    }
                    .disabled(existingShift != nil)
                } header: {
                    Text("Portfolio Specialist")
                }
                
                Section {
                    DatePicker("Activation Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Finalization Time", selection: $endTime, in: startTime..., displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Operational Window")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote.bold())
                    }
                }
                
                if let existing = existingShift {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                let success = await shiftVM.deleteShift(existing.id, boutiqueId: boutiqueId)
                                if success { dismiss() }
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Void Operational Shift")
                                    .font(.headline.bold())
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingShift == nil ? "Schedule Objective" : "Refine Objective")
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
                        Task { await saveShift() }
                    } label: {
                        ZStack {
                            Circle().fill(selectedEmployeeId == nil || startTime >= endTime ? Color.secondary.opacity(0.1) : Color.accentColor).frame(width: 36, height: 36)
                            Image(systemName: "checkmark").font(.custom("Helvetica", size: 14)).fontWeight(.bold).foregroundColor(.white)
                        }
                    }
                    .disabled(selectedEmployeeId == nil || startTime >= endTime)
                }
            }
            .alert("Conflict Intelligence Triggered", isPresented: $showConflictAlert) {
                Button("Override", role: .destructive) {
                    Task { await saveShiftForced() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This specialist is currently assigned to a concurrent objective. Proceed with overlap?")
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
        if shiftVM.hasConflict(for: empId, start: startTime, end: endTime, excludingShiftId: existingShift?.id) {
            showConflictAlert = true
            return
        }
        await saveShiftForced()
    }

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
}
