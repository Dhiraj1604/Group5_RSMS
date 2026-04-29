//
//  VIPAppointmentsListView.swift
//  Group5_RSMS
//

import SwiftUI

struct VIPAppointmentsListView: View {
    @ObservedObject var vm: VIPEventViewModel
    let boutiqueId: UUID
    @State private var searchText = ""

    var filteredAppointments: [VIPAppointment] {
        let list = vm.appointments.filter { $0.boutiqueId == boutiqueId }
        if searchText.isEmpty {
            return list.sorted { $0.appointmentDate < $1.appointmentDate }
        } else {
            return list.filter { appt in
                let guest = vm.allGuests.first { $0.id == appt.guestId }
                let guestName = guest?.fullName ?? ""
                return guestName.localizedCaseInsensitiveContains(searchText) ||
                       appt.type.localizedCaseInsensitiveContains(searchText) ||
                       (appt.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.appointmentDate < $1.appointmentDate }
        }
    }

    var upcomingAppointments: [VIPAppointment] {
        filteredAppointments.filter { $0.status == "scheduled" }
    }

    var pastAppointments: [VIPAppointment] {
        filteredAppointments.filter { $0.status != "scheduled" }
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            if vm.appointments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No Appointments")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Text("Tap + to schedule an appointment.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !upcomingAppointments.isEmpty {
                        Section {
                            ForEach(upcomingAppointments) { appt in
                                appointmentRow(appt)
                            }
                        } header: {
                            Text("Upcoming").foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                    }
                    
                    if !pastAppointments.isEmpty {
                        Section {
                            ForEach(pastAppointments) { appt in
                                appointmentRow(appt)
                            }
                        } header: {
                            Text("Completed & Cancelled").foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search by guest or type")
            }
        }
    }

    @ViewBuilder
    private func appointmentRow(_ appt: VIPAppointment) -> some View {
        let guest = vm.allGuests.first { $0.id == appt.guestId }
        
        NavigationLink(destination: guest != nil ? AnyView(VIPGuestDetailView(vm: vm, guest: guest!)) : AnyView(Text("Guest not found"))) {
            HStack(alignment: .center, spacing: RSMSTheme.Spacing.md) {
                VStack(spacing: 4) {
                    Text(appt.appointmentDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    Text(appt.appointmentDate.formatted(.dateTime.hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                .frame(width: 50)
                .padding(.vertical, 4)
                .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(guest?.fullName ?? "Unknown Guest")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    
                    Text(appt.type)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    
                    if let title = appt.title, !title.isEmpty {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                if appt.status != "scheduled" {
                    Text(appt.status.capitalized)
                        .font(.caption2).fontWeight(.bold)
                        .foregroundStyle(appt.status == "completed" ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (appt.status == "completed" ? RSMSTheme.Colors.success : RSMSTheme.Colors.error).opacity(0.15)
                        )
                        .clipShape(Capsule())
                } else if appt.appointmentDate < Date() {
                    Text("Overdue")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RSMSTheme.Colors.error.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .listRowBackground(RSMSTheme.Colors.backgroundElevated)
        .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
        .swipeActions(edge: .trailing) {
            if appt.status == "scheduled" {
                Button(role: .destructive) {
                    Task { await vm.updateAppointmentStatus(appointmentId: appt.id, newStatus: "cancelled") }
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
                
                Button {
                    Task { await vm.updateAppointmentStatus(appointmentId: appt.id, newStatus: "completed") }
                } label: {
                    Label("Complete", systemImage: "checkmark.circle")
                }
                .tint(RSMSTheme.Colors.success)
            }
        }
    }
}
