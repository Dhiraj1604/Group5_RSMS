//
//  ScheduleAppointmentSheet.swift
//  Group5_RSMS
//

import SwiftUI

struct ScheduleAppointmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: VIPEventViewModel
    let boutiqueId: UUID
    let preselectedGuest: VIPGuest?
    
    @State private var selectedGuestId: UUID?
    @State private var appointmentDate = Date()
    @State private var type = "In-Store Styling"
    @State private var title = ""
    @State private var notes = ""
    
    let appointmentTypes = [
        "In-Store Styling",
        "Virtual Consultation",
        "Repair/Service",
        "Collection Preview"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Guest Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Client").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            if let pre = preselectedGuest {
                                Text(pre.fullName)
                                    .font(.subheadline)
                                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(RSMSTheme.Colors.backgroundElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Picker("Select Guest", selection: $selectedGuestId) {
                                    Text("Select a Client").tag(UUID?.none)
                                    ForEach(vm.allGuests) { guest in
                                        Text(guest.fullName).tag(Optional(guest.id))
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(RSMSTheme.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(RSMSTheme.Colors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        // Date & Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            DatePicker("Appointment Time", selection: $appointmentDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(RSMSTheme.Colors.accentGold)
                                .padding()
                                .background(RSMSTheme.Colors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Type").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            Picker("Type", selection: $type) {
                                ForEach(appointmentTypes, id: \.self) { t in
                                    Text(t).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(RSMSTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(RSMSTheme.Colors.backgroundElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        fieldRow("Title (Optional)", text: $title, placeholder: "e.g., Summer Collection fitting")
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(RSMSTheme.Colors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let gid = preselectedGuest?.id ?? selectedGuestId
                        guard let guestId = gid else { return }
                        
                        Task {
                            await vm.scheduleAppointment(
                                guestId: guestId,
                                boutiqueId: boutiqueId,
                                title: title.isEmpty ? nil : title,
                                date: appointmentDate,
                                type: type,
                                notes: notes.isEmpty ? nil : notes
                            )
                        }
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .disabled(preselectedGuest == nil && selectedGuestId == nil)
                }
            }
        }
    }
    
    private func fieldRow(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
            TextField(placeholder, text: text)
                .padding()
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
