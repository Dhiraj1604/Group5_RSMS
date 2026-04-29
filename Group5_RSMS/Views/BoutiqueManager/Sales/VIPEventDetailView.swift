//
//  VIPEventDetailView.swift
//  Group5_RSMS
//
//  Per-event detail: Guest list + Product Collection tabs.
//

import SwiftUI

struct VIPEventDetailView: View {
    @ObservedObject var vm: VIPEventViewModel
    let event: VIPEvent

    var currentEvent: VIPEvent {
        vm.events.first { $0.id == event.id } ?? event
    }

    @State private var selectedSeg = 0     // 0 = Guests, 1 = Collection
    @State private var showInviteSheet     = false
    @State private var showAddProduct      = false
    @State private var showStatusPicker    = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                // Event summary card
                eventSummaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                if currentEvent.status == "completed" {
                    attendanceSummaryCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                // Sub-tab picker
                Picker("Detail", selection: $selectedSeg) {
                    Text("Guests").tag(0)
                    Text("Collection").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if selectedSeg == 0 {
                    guestsSection
                } else {
                    collectionSection
                }
            }
        }
        .navigationTitle(currentEvent.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showStatusPicker = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                    
                    Button {
                        if selectedSeg == 0 { showInviteSheet = true }
                        else { showAddProduct = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteGuestSheet(vm: vm, event: event)
        }
        .sheet(isPresented: $showAddProduct) {
            AddProductToCollectionSheet(vm: vm, event: event)
        }
        .confirmationDialog("Change Event Status", isPresented: $showStatusPicker) {
            if currentEvent.status == "upcoming" {
                Button("Mark as Ongoing")  { Task { await vm.updateStatus(event: currentEvent, newStatus: "ongoing") } }
            }
            if currentEvent.status == "upcoming" || currentEvent.status == "ongoing" {
                Button("Mark as Completed") { Task { await vm.updateStatus(event: currentEvent, newStatus: "completed") } }
                Button("Cancel Event", role: .destructive) { Task { await vm.updateStatus(event: currentEvent, newStatus: "cancelled") } }
            }
            Button("Delete Event", role: .destructive) {
                Task {
                    await vm.deleteEvent(currentEvent)
                    dismiss()
                }
            }
            Button("Dismiss", role: .cancel) {}
        }
        .task { await vm.loadEventDetail(eventId: currentEvent.id) }
    }

    // MARK: - Summary Card

    private var eventSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(currentEvent.formattedDate, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    if let venue = currentEvent.venue {
                        Label(venue, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let cap = event.guestCapacity {
                        Text("\(vm.selectedEventGuests.filter { $0.rsvpStatus == "confirmed" || $0.rsvpStatus == "attended" }.count) / \(cap)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Text("confirmed")
                            .font(.caption2)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }

    // MARK: - Attendance Summary Card
    
    @ViewBuilder
    private var attendanceSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attendance Report")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(vm.selectedEventGuests.count)")
                        .font(.title2).bold()
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    Text("Total Invited")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading) {
                    Text("\(vm.selectedEventGuests.filter { $0.rsvpStatus == "attended" }.count)")
                        .font(.title2).bold()
                        .foregroundStyle(.green)
                    Text("Attended")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }

    // MARK: - Guests Section

    private var guestsSection: some View {
        Group {
            if vm.isLoadingDetail {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.selectedEventGuests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No guests invited yet")
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.selectedEventGuests) { invite in
                        GuestInviteRow(invite: invite) { newStatus in
                            Task { await vm.updateRSVP(invite: invite, status: newStatus) }
                        }
                        .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                        .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await vm.removeFromEvent(invite: invite) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Collection Section

    private var collectionSection: some View {
        Group {
            if vm.isLoadingDetail {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.selectedEventCollection.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tag.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No products in collection")
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(vm.selectedEventCollection) { item in
                        CollectionItemRow(item: item, vm: vm)
                            .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                            .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.removeFromCollection(item: item) }
                                } label: {
                                    Label("Remove", systemImage: "minus.circle")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

// MARK: - Guest Invite Row

struct GuestInviteRow: View {
    let invite: VIPEventGuest
    let onStatusChange: (String) -> Void

    private var rsvpColor: Color {
        switch invite.rsvpStatus {
        case "confirmed", "attended": return .green
        case "declined", "no_show":   return .red
        default:                       return RSMSTheme.Colors.accentGold
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar initials
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(invite.guest?.initials ?? "?")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(invite.guest?.fullName ?? "Unknown Guest")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                if let email = invite.guest?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                if let phone = invite.guest?.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
            Spacer()
            Menu {
                ForEach(["invited","confirmed","declined","attended","no_show"], id: \.self) { s in
                    Button(s.replacingOccurrences(of: "_", with: " ").capitalized) {
                        onStatusChange(s)
                    }
                }
            } label: {
                Text((invite.rsvpStatus ?? "invited").replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(rsvpColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(rsvpColor.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Collection Item Row

struct CollectionItemRow: View {
    let item: VIPEventCollectionItem
    @ObservedObject var vm: VIPEventViewModel
    @Environment(AppState.self) private var appState

    var productName: String {
        appState.products.first(where: { $0.id == item.productId })?.name ?? "Product"
    }
    var productSKU: String {
        appState.products.first(where: { $0.id == item.productId })?.sku ?? "-"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "tag.fill")
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(productName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                HStack(spacing: 8) {
                    Text(productSKU)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    if let price = item.specialPrice {
                        Text("Event: ₹\(String(format: "%.0f", price))")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.accentGoldDark)
                    }
                }
            }
            Spacer()
            if item.isReserved == true {
                Label("Reserved", systemImage: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

