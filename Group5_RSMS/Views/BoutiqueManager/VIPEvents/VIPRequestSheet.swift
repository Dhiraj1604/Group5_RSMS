//
//  VIPRequestSheet.swift
//  Group5_RSMS
//

import SwiftUI

struct VIPRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    let client: VIPClient
    @ObservedObject var tasksVM: BMTasksViewModel
    
    @State private var requestDetails = ""
    @State private var selectedEmployeeId: UUID?
    @State private var showToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text("Log Request for \(client.name)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Request Details")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            
                            TextEditor(text: $requestDetails)
                                .frame(height: 120)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(RSMSTheme.Colors.surfacePrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                                )
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Assign Follow-up Task To")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            
                            Menu {
                                ForEach(tasksVM.staff) { employee in
                                    Button(employee.name) {
                                        selectedEmployeeId = employee.id
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedEmployeeName)
                                        .foregroundColor(selectedEmployeeId == nil ? RSMSTheme.Colors.textSecondary : RSMSTheme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                }
                                .padding()
                                .background(RSMSTheme.Colors.surfacePrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                                )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Log VIP Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRequestAndCreateTask()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .disabled(requestDetails.isEmpty || selectedEmployeeId == nil)
                }
            }
        }
    }
    
    private var selectedEmployeeName: String {
        if let id = selectedEmployeeId, let emp = tasksVM.staff.first(where: { $0.id == id }) {
            return emp.name
        }
        return "Select Staff Member..."
    }
    
    private func saveRequestAndCreateTask() {
        guard let storeId = appState.currentStoreID, let empId = selectedEmployeeId else { return }
        
        // Auto-create a task in the Task manager
        let taskTitle = "VIP Request: \(client.name)"
        let newTask = StoreTask(
            id: UUID(),
            boutiqueId: storeId,
            title: taskTitle,
            description: requestDetails,
            assignedTo: empId,
            isCompleted: false,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) // Due in 3 days
        )
        
        Task {
            await tasksVM.addTask(newTask)
            dismiss()
        }
    }
}
