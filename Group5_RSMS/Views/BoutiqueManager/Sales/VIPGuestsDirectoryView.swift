//
//  VIPGuestsDirectoryView.swift
//  Group5_RSMS
//
//  Boutique VIP Guest Directory — searchable list of VIP customers.
//

import SwiftUI

struct VIPGuestsDirectoryView: View {
    @ObservedObject var vm: VIPEventViewModel
    let boutiqueId: UUID
    @State private var searchText = ""

    var filtered: [VIPGuest] {
        if searchText.isEmpty { return vm.allGuests }
        return vm.allGuests.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.email?.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if vm.isLoadingGuests {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.allGuests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No VIP Guests Yet")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Text("Tap + to add your first VIP customer.")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
//                     ForEach(filtered) { guest in
//                         GuestDirectoryRow(guest: guest)
                    Section {
                        ForEach(filtered) { guest in
                            NavigationLink(destination: VIPGuestDetailView(vm: vm, guest: guest)) {
                                GuestDirectoryRow(guest: guest)
                            }
                            .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                            .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.deleteGuest(guest) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "Search by name or email")
            }
        }
    }
}

// MARK: - Guest Directory Row

struct GuestDirectoryRow: View {
    let guest: VIPGuest

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(guest.initials)
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(guest.fullName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                HStack(spacing: 6) {
                    if let email = guest.email {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    }
                    if let phone = guest.phone {
                        Text("· \(phone)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
