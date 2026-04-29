//
//  VIPEventViewModel.swift
//  Group5_RSMS
//
//  ObservableObject ViewModel powering the VIP Events tab.
//  Handles events list, guest directory, and per-event detail state.
//

import SwiftUI
import Combine

@MainActor
class VIPEventViewModel: ObservableObject {

    // MARK: - Events
    @Published var events: [VIPEvent] = []
    @Published var isLoadingEvents = false
    @Published var eventError: String?

    // MARK: - Guest Directory
    @Published var allGuests: [VIPGuest] = []
    @Published var isLoadingGuests = false

    // MARK: - Per-event detail (loaded on demand)
    @Published var selectedEventGuests: [VIPEventGuest] = []
    @Published var selectedEventCollection: [VIPEventCollectionItem] = []
    @Published var isLoadingDetail = false

    private let service = VIPEventService.shared

    // MARK: - Load Events

    func loadEvents(boutiqueId: UUID) async {
        isLoadingEvents = true
        eventError = nil
        do {
            events = try await service.fetchEvents(boutiqueId: boutiqueId)
        } catch {
            eventError = error.localizedDescription
        }
        isLoadingEvents = false
    }

    // MARK: - Create Event

    func createEvent(boutiqueId: UUID, title: String, description: String?,
                     eventDate: Date?, capacity: Int?, venue: String?,
                     theme: String?, hostId: UUID?) async {
        guard boutiqueId.uuidString != "00000000-0000-0000-0000-000000000000" else {
            eventError = "No boutique assigned. Please contact your administrator."
            return
        }
        
        var ev = VIPEvent(
            id:              UUID(),
            boutiqueId:      boutiqueId,
            title:           title,
            description:     description,
            eventDate:       eventDate,
            guestCapacity:   capacity,
            venue:           venue,
            status:          "upcoming",
            hostEmployeeId:  hostId,
            theme:           theme,
            createdAt:       Date()
        )
        do {
            try await service.createEvent(ev)
            events.insert(ev, at: 0)
        } catch {
            eventError = error.localizedDescription
        }
    }

    // MARK: - Cancel / Complete Event

    func updateStatus(event: VIPEvent, newStatus: String) async {
        do {
            try await service.updateEventStatus(eventId: event.id, status: newStatus)
            if let idx = events.firstIndex(where: { $0.id == event.id }) {
                events[idx].status = newStatus
            }
        } catch {
            eventError = error.localizedDescription
        }
    }

    // MARK: - Delete Event

    func deleteEvent(_ event: VIPEvent) async {
        do {
            try await service.deleteEvent(eventId: event.id)
            events.removeAll { $0.id == event.id }
        } catch {
            eventError = error.localizedDescription
        }
    }

    // MARK: - Guest Directory

    func loadGuests(boutiqueId: UUID) async {
        isLoadingGuests = true
        do {
            allGuests = try await service.fetchGuests(boutiqueId: boutiqueId)
        } catch {
            eventError = error.localizedDescription
        }
        isLoadingGuests = false
    }

    func addGuest(boutiqueId: UUID, name: String, email: String?,
                  phone: String?, preferences: String?,
                  addedBy: UUID?) async {
        // Guard: boutiqueId must be a real store — prevents FK violation
        guard boutiqueId.uuidString != "00000000-0000-0000-0000-000000000000" else {
            eventError = "No boutique assigned. Please contact your administrator."
            return
        }
        let guest = VIPGuest(
            id:           UUID(),
            boutiqueId:   boutiqueId,
            fullName:     name,
            email:        email?.isEmpty == true ? nil : email,
            phone:        phone?.isEmpty == true ? nil : phone,
            addedBy:      addedBy, // Pass the appState.managerAuthId here
            preferences:  preferences?.isEmpty == true ? nil : preferences,
            createdBy:    Date()
        )
        do {
            try await service.addGuest(guest)
            allGuests.insert(guest, at: 0)
        } catch {
            eventError = error.localizedDescription
        }
    }

    func deleteGuest(_ guest: VIPGuest) async {
        do {
            try await service.deleteGuest(guestId: guest.id)
            allGuests.removeAll { $0.id == guest.id }
        } catch {
            eventError = error.localizedDescription
        }
    }

    // MARK: - Event Detail (guests + collection)

    func loadEventDetail(eventId: UUID) async {
        isLoadingDetail = true
        async let guestsResult  = service.fetchEventGuests(eventId: eventId)
        async let collResult    = service.fetchCollection(eventId: eventId)
        do {
            let (g, c) = try await (guestsResult, collResult)
            selectedEventGuests     = g
            selectedEventCollection = c
        } catch {
            eventError = error.localizedDescription
        }
        isLoadingDetail = false
    }

    func inviteGuest(eventId: UUID, guestId: UUID) async {
        do {
            try await service.inviteGuest(eventId: eventId, guestId: guestId)
            // Reload detail to get joined guest info
            await loadEventDetail(eventId: eventId)
        } catch {
            eventError = error.localizedDescription
        }
    }

    func updateRSVP(invite: VIPEventGuest, status: String) async {
        do {
            try await service.updateRSVP(inviteId: invite.id, status: status)
            if let idx = selectedEventGuests.firstIndex(where: { $0.id == invite.id }) {
                selectedEventGuests[idx].rsvpStatus = status
            }
        } catch {
            eventError = error.localizedDescription
        }
    }

    func removeFromEvent(invite: VIPEventGuest) async {
        do {
            try await service.removeEventGuest(inviteId: invite.id)
            selectedEventGuests.removeAll { $0.id == invite.id }
        } catch {
            eventError = error.localizedDescription
        }
    }

    func addToCollection(eventId: UUID, productId: UUID, specialPrice: Double?) async {
        let order = selectedEventCollection.count
        do {
            try await service.addToCollection(eventId: eventId, productId: productId, order: order, specialPrice: specialPrice)
            await loadEventDetail(eventId: eventId)
        } catch {
            eventError = error.localizedDescription
        }
    }

    func removeFromCollection(item: VIPEventCollectionItem) async {
        do {
            try await service.removeFromCollection(itemId: item.id)
            selectedEventCollection.removeAll { $0.id == item.id }
        } catch {
            eventError = error.localizedDescription
        }
    }

    // MARK: - Helpers

    var upcomingEvents: [VIPEvent] {
        events.filter { $0.status == "upcoming" || $0.status == "ongoing" }
    }

    var pastEvents: [VIPEvent] {
        events.filter { $0.status == "completed" || $0.status == "cancelled" }
    }

    func confirmedCount(for eventId: UUID) -> Int {
        selectedEventGuests.filter {
            $0.eventId == eventId && ($0.rsvpStatus == "confirmed" || $0.rsvpStatus == "attended")
        }.count
    }
}
