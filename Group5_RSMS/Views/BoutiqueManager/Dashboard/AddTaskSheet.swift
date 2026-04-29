//
//  AddTaskSheet.swift
//  Group5_RSMS
//

import SwiftUI

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let boutiqueId: UUID
    let staff: [Employee]
    let onSave: (StoreTask) -> Void
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date()
    @State private var assignedTo: UUID? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                        .font(RSMSTheme.Typography.bodyCopy1)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .font(RSMSTheme.Typography.bodyCopy2)
                } header: {
                    Text("Task Details")
                }
                
                Section {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    Picker("Assign To", selection: $assignedTo) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(staff) { employee in
                            Text(employee.name).tag(UUID?.some(employee.id))
                        }
                    }
                } header: {
                    Text("Assignment")
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.error)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newTask = StoreTask(
                            boutiqueId: boutiqueId,
                            title: title,
                            description: description.isEmpty ? nil : description,
                            assignedTo: assignedTo,
                            status: .pending,
                            dueDate: dueDate
                        )
                        onSave(newTask)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
    }
}
