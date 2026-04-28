//
//  AddTaskSheet.swift
//  Group5_RSMS
//
//  Premium Add Task Sheet - Native iPadOS style.
//  Enhanced with symbol-only toolbars and professional intelligence styling.
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
            SwiftUI.Form {
                Section {
                    TextField("Intelligence Objective", text: $title)
                        .font(.headline)
                    
                    TextField("Detailed Instructions (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.subheadline)
                } header: {
                    Text("Strategic Directive")
                }
                
                Section {
                    DatePicker("Target Completion", selection: $dueDate, displayedComponents: .date)
                    
                    Picker("Designated Specialist", selection: $assignedTo) {
                        Text("Unassigned Portfolio").tag(UUID?.none)
                        ForEach(staff) { employee in
                            Text(employee.name).tag(UUID?.some(employee.id))
                        }
                    }
                } header: {
                    Text("Execution & Assignment")
                }
            }
            .navigationTitle("New Objective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
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
                    } label: {
                        ZStack {
                            Circle().fill(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.1) : Color.accentColor).frame(width: 36, height: 36)
                            Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
