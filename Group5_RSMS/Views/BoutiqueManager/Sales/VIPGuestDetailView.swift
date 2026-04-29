//
//  VIPGuestDetailView.swift
//  Group5_RSMS
//
//  Detailed profile view for a VIP Client, showing preferences, 
//  purchase history, and logged requests.
//

import SwiftUI

struct VIPGuestDetailView: View {
    @Environment(AppState.self) private var appState
    @ObservedObject var vm: VIPEventViewModel
    let guest: VIPGuest
    
    // Mock purchase history for now
    private let mockPurchases = [
        ("Constella Bracelet", "₹69,000", "12 Oct 2025"),
        ("Maharaja Diamond Ring", "₹5,000,000", "05 Jan 2026")
    ]
    
    @State private var showScheduleAppointment = false
    
    var guestAppointments: [VIPAppointment] {
        vm.appointments.filter { $0.guestId == guest.id }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    headerSection
                    
                    if guest.preferences != nil {
                        detailsSection
                    }
                    
                    purchaseHistorySection
                    
                    appointmentsSection
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
                .padding(.bottom, RSMSTheme.Spacing.xxl)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
        
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScheduleAppointment = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showScheduleAppointment) {
            ScheduleAppointmentSheet(vm: vm, boutiqueId: appState.currentStoreID ?? UUID(), preselectedGuest: guest)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 70, height: 70)
                Text(guest.initials)
                    .font(.title).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.fullName)
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                
                
                if let email = guest.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                if let phone = guest.phone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Preferences", icon: "person.text.rectangle.fill")
            
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                if let prefs = guest.preferences {
                    Text(prefs)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
                if let last = guest.lastVisit {
                    detailRow(label: "Last Visit", value: last.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    
    private var purchaseHistorySection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Purchase History", icon: "bag.fill")
            
            VStack(spacing: 0) {
                ForEach(mockPurchases.indices, id: \.self) { idx in
                    let purchase = mockPurchases[idx]
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(purchase.0)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Text(purchase.2)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        }
                        Spacer()
                        Text(purchase.1)
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                    .padding(RSMSTheme.Spacing.md)
                    
                    if idx < mockPurchases.count - 1 {
                        Divider().background(RSMSTheme.Colors.borderLight)
                    }
                }
            }
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Appointments", icon: "calendar")
            
            if guestAppointments.isEmpty {
                Text("No appointments scheduled.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .padding(RSMSTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                    .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            } else {
                VStack(spacing: RSMSTheme.Spacing.md) {
                    ForEach(guestAppointments.sorted { $0.appointmentDate < $1.appointmentDate }) { appt in
                        HStack(alignment: .top, spacing: RSMSTheme.Spacing.md) {
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
                                Text(appt.type)
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                if let title = appt.title {
                                    Text(title)
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
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
                        .padding(RSMSTheme.Spacing.md)
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
                        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                        .opacity(appt.status == "scheduled" ? 1.0 : 0.6)
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
            }
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(RSMSTheme.Colors.accentGold)
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption).fontWeight(.bold)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
    }
}
