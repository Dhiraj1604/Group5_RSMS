//
//  BMSalesTab.swift
//  Group5_RSMS
//
//  Boutique Manager — VIP & Events tab.
//

import SwiftUI

struct BMSalesTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var vm = VIPEventViewModel()
    @State private var selectedSeg = 0          // 0 = Events, 1 = Guests, 2 = Appointments
    @State private var showCreateEvent = false
    @State private var showAddGuest    = false
    @State private var showScheduleAppointment = false

    var boutiqueId: UUID {
        appState.currentStoreID ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Segmented picker
                    Picker("Section", selection: $selectedSeg) {
                        Text("Events").tag(0)
                        Text("VIP Guests").tag(1)
                        Text("Appointments").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if selectedSeg == 0 {
                        VIPEventsListView(vm: vm, boutiqueId: boutiqueId)
                    } else if selectedSeg == 1 {
                        VIPGuestsDirectoryView(vm: vm, boutiqueId: boutiqueId)
                    } else {
                        VIPAppointmentsListView(vm: vm, boutiqueId: boutiqueId)
                    }
                }
            }
            .navigationTitle(selectedSeg == 0 ? "VIP Events" : (selectedSeg == 1 ? "Guest Directory" : "Appointments"))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                if selectedSeg != 2 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if selectedSeg == 0 { showCreateEvent = true }
                            else if selectedSeg == 1 { showAddGuest = true }
                            else { showScheduleAppointment = true }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventSheet(vm: vm, boutiqueId: boutiqueId)
            }
            .sheet(isPresented: $showAddGuest) {
                AddGuestSheet(vm: vm, boutiqueId: boutiqueId)
            }
            .sheet(isPresented: $showScheduleAppointment) {
                ScheduleAppointmentSheet(vm: vm, boutiqueId: boutiqueId, preselectedGuest: nil)
            }
            .task {
                await vm.loadEvents(boutiqueId: boutiqueId)
                await vm.loadGuests(boutiqueId: boutiqueId)
                await vm.loadAppointments(boutiqueId: boutiqueId)
            }
            .alert("Error", isPresented: Binding(
                get: { vm.eventError != nil },
                set: { if !$0 { vm.eventError = nil } }
            )) {
                Button("OK", role: .cancel) { vm.eventError = nil }
            } message: {
                Text(vm.eventError ?? "")
            }
        }
    }
}

#Preview {
    BMSalesTab()
        .environment(AppState())
}
