//
//  VIPEventSheets.swift
//  Group5_RSMS
//
//  All bottom sheets for the VIP Events tab:
//   • CreateEventSheet   — create a new VIP event
//   • AddGuestSheet      — add a guest to the boutique directory
//   • InviteGuestSheet   — invite a directory guest to a specific event
//   • AddProductToCollectionSheet — add a product to an event's showcase
//

import SwiftUI

// MARK: - CreateEventSheet

struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @ObservedObject var vm: VIPEventViewModel
    let boutiqueId: UUID

    @State private var title        = ""
    @State private var description  = ""
    @State private var eventDate    = Date().addingTimeInterval(7 * 86400)
    @State private var capacity     = ""
    @State private var venue        = ""
    @State private var theme        = ""
    @State private var isSaving     = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        formField("Event Title *", text: $title, placeholder: "e.g. Spring Couture Preview")
                        formField("Theme", text: $theme, placeholder: "e.g. Black Tie")
                        formField("Venue", text: $venue, placeholder: "e.g. VIP Lounge, Floor 2")
                        formField("Description", text: $description, placeholder: "Notes, agenda…", multiline: true)

                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Date").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            DatePicker("", selection: $eventDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(RSMSTheme.Colors.accentGold)
                                .padding()
                                .background(RSMSTheme.Colors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        formField("Guest Capacity", text: $capacity, placeholder: "e.g. 30", keyboard: .numberPad)

                        Spacer().frame(height: 8)

//                         Button {
//                             isSaving = true
//                             Task {
//                                 await vm.createEvent(
//                                     boutiqueId:  boutiqueId,
//                                     title:       title.trimmingCharacters(in: .whitespaces),
//                                     description: description.isEmpty ? nil : description,
//                                     eventDate:   eventDate,
//                                     capacity:    Int(capacity),
//                                     venue:       venue.isEmpty ? nil : venue,
//                                     theme:       theme.isEmpty ? nil : theme,
//                                     hostId:      nil // Reverting: must be nil unless we pick a real Employee ID
//                                 )
//                                 isSaving = false
//                                 dismiss()
//                             }
//                         } label: {
//                             HStack {
//                                 if isSaving { ProgressView().tint(.black) }
//                                 Text(isSaving ? "Creating…" : "Create Event")
//                             }
//                             .frame(maxWidth: .infinity)
//                         }
//                         .buttonStyle(GoldButtonStyle())
//                         .disabled(!canSave || isSaving)
//                         .opacity(!canSave ? 0.6 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New VIP Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        isSaving = true
                        Task {
                            await vm.createEvent(
                                boutiqueId:  boutiqueId,
                                title:       title.trimmingCharacters(in: .whitespaces),
                                description: description.isEmpty ? nil : description,
                                eventDate:   eventDate,
                                capacity:    Int(capacity),
                                venue:       venue.isEmpty ? nil : venue,
                                theme:       theme.isEmpty ? nil : theme,
                                hostId:      nil // Reverting: must be nil unless we pick a real Employee ID
                            )
                            isSaving = false
                            dismiss()
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .disabled(!canSave || isSaving)
                    .opacity(!canSave ? 0.6 : 1)
                }
            }
        }
    }

    // Reusable form field
    @ViewBuilder
    private func formField(_ label: String, text: Binding<String>, placeholder: String,
                           multiline: Bool = false,
                           keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
            if multiline {
                TextEditor(text: text)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
            } else {
                FocusableTextField(placeholder: placeholder, text: text, keyboard: keyboard)
            }
        }
    }
}

// MARK: - AddGuestSheet

struct AddGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @ObservedObject var vm: VIPEventViewModel
    let boutiqueId: UUID

    @State private var name         = ""
    @State private var email        = ""
    @State private var phone        = ""
    @State private var tier         = "silver"
    @State private var preferences  = ""
    @State private var isSaving     = false
    private var isPhoneValid: Bool {
        let digits = phone.filter { $0.isNumber }
        return phone.isEmpty || digits.count == 10
    }

    private var canSave: Bool { 
        !name.trimmingCharacters(in: .whitespaces).isEmpty && isPhoneValid 
    }
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        fieldRow("Full Name *", text: $name, placeholder: "e.g. Aisha Mehta")
                        fieldRow("Email", text: $email, placeholder: "aisha@example.com", keyboard: .emailAddress)
                        VStack(alignment: .leading, spacing: 4) {
                            fieldRow("Phone", text: $phone, placeholder: "9876543210", keyboard: .phonePad)
                            if !phone.isEmpty && !isPhoneValid {
                                Text("Phone number must be exactly 10 digits")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        fieldRow("Style Preferences", text: $preferences, placeholder: "e.g. Prefers minimalist cuts")

                        // Tier picker
//                         VStack(alignment: .leading, spacing: 8) {
//                             Text("VIP Tier").font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
//                             Picker("Tier", selection: $tier) {
//                                 Text("🥈 Silver").tag("silver")
//                                 Text("🥇 Gold").tag("gold")
//                                 Text("💎 Platinum").tag("platinum")
//                             }
//                             .pickerStyle(.segmented)
//                         }


                        Button {
                            isSaving = true
                            Task {
                                await vm.addGuest(
                                    boutiqueId:   boutiqueId,
                                    name:         name.trimmingCharacters(in: .whitespaces),
                                    email:        email.isEmpty ? nil : email,
                                    phone:        phone.isEmpty ? nil : phone,
                                    tier:         tier,
                                    preferences:  preferences.isEmpty ? nil : preferences,
                                    addedBy:      appState.managerAuthId // Fix for added_by_fkey
                                )
                                isSaving = false
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if isSaving { ProgressView().tint(.black) }
                                Text(isSaving ? "Adding…" : "Add VIP Guest")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(!canSave || isSaving)
                        .opacity(!canSave ? 0.6 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New VIP Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func fieldRow(_ label: String, text: Binding<String>, placeholder: String,
                          keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
            FocusableTextField(placeholder: placeholder, text: text, keyboard: keyboard)
        }
    }
}

// MARK: - InviteGuestSheet

struct InviteGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: VIPEventViewModel
    let event: VIPEvent

    @State private var searchText = ""

    // Guests not already invited
    private var alreadyInvitedIds: Set<UUID> {
        Set(vm.selectedEventGuests.compactMap { $0.guestId })
    }

//     private var availableGuests: [VIPGuest] {
//         let eligible = vm.allGuests.filter { !alreadyInvitedIds.contains($0.id) }
//         if searchText.isEmpty { return eligible }
//         return eligible.filter {
    private var filteredGuests: [VIPGuest] {
        if searchText.isEmpty { return vm.allGuests }
        return vm.allGuests.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.email?.localizedCaseInsensitiveContains(searchText) == true)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
//                 if availableGuests.isEmpty && searchText.isEmpty {
                if vm.allGuests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("All directory guests are already invited.")
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
//                     List(availableGuests) { guest in
//                         Button {
//                             Task {
//                                 await vm.inviteGuest(eventId: event.id, guestId: guest.id)
//                                 dismiss()
                    List(filteredGuests) { guest in
                        let isInvited = alreadyInvitedIds.contains(guest.id)
                        
                        Button {
                            if !isInvited {
                                Task {
                                    await vm.inviteGuest(eventId: event.id, guestId: guest.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                                        .frame(width: 38, height: 38)
                                    Text(guest.initials)
                                        .font(.caption).fontWeight(.bold)
                                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(guest.fullName)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                    if let email = guest.email {
                                        Text(email).font(.caption)
                                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                    }
                                }
                                Spacer()
//                                 Image(systemName: "plus.circle")
//                                     .foregroundStyle(RSMSTheme.Colors.accentGold)
                                Image(systemName: isInvited ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundStyle(isInvited ? .green : RSMSTheme.Colors.accentGold)
                            }
                        }
                        .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                        .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search guests")
                }
            }
//             .navigationTitle("Invite Guest")
//             .navigationBarTitleDisplayMode(.inline)
//             .toolbar {
//                 ToolbarItem(placement: .topBarLeading) {
//                     Button("Cancel") { dismiss() }.foregroundStyle(RSMSTheme.Colors.textSecondary)
            .navigationTitle("Invite Guests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.bold).foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
    }
}

// MARK: - AddProductToCollectionSheet

struct AddProductToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @ObservedObject var vm: VIPEventViewModel
    let event: VIPEvent

    @State private var searchText    = ""
    @State private var specialPrice  = ""

    private var alreadyAddedIds: Set<UUID> {
        Set(vm.selectedEventCollection.compactMap { $0.productId })
    }

    private var availableProducts: [Product] {
        let eligible = appState.products.filter { !alreadyAddedIds.contains($0.id) }
        if searchText.isEmpty { return eligible }
        return eligible.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Optional event price field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Optional: Event-night special price (₹)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        FocusableTextField(placeholder: "Leave blank to use base price", text: $specialPrice, keyboard: .decimalPad)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    List(availableProducts) { product in
                        Button {
                            Task {
                                await vm.addToCollection(
                                    eventId:      event.id,
                                    productId:    product.id,
                                    specialPrice: Double(specialPrice)
                                )
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                                        .frame(width: 38, height: 38)
                                    Image(systemName: "tag.fill")
                                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                    Text(product.sku)
                                        .font(.caption)
                                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                            }
                        }
                        .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                        .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search by name or SKU")
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Reusable Views

struct FocusableTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(isFocused ? "" : placeholder, text: $text)
            .focused($isFocused)
            .keyboardType(keyboard)
            .padding()
            .background(RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(RSMSTheme.Colors.textPrimary)
    }
}
