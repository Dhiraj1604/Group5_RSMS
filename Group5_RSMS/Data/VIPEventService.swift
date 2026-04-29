//
//  VIPEventService.swift
//  Group5_RSMS
//
//  Service layer for all VIP Events Supabase operations.
//  Tables: vip_events, vip_guests, vip_event_guests, vip_events_collection
//

import Foundation
import Supabase

final class VIPEventService {
    static let shared = VIPEventService()
    private let client = SupabaseManager.shared.client
    private init() {}

    // MARK: - vip_events

    /// Fetch all events for a boutique, ordered by event_date ascending.
    func fetchEvents(boutiqueId: UUID) async throws -> [VIPEvent] {
        let result: [VIPEvent] = try await client
            .from("vip_events")
            .select("*")
            .eq("boutique_id", value: boutiqueId)
            .order("event_date", ascending: true)
            .execute()
            .value
        return result
    }

    /// Create a new VIP event.
    func createEvent(_ event: VIPEvent) async throws {
        try await client
            .from("vip_events")
            .insert(event.insertPayload)
            .execute()
    }

    /// Update an event's status (upcoming → completed / cancelled).
    func updateEventStatus(eventId: UUID, status: String) async throws {
        try await client
            .from("vip_events")
            .update(["status": status])
            .eq("id", value: eventId)
            .execute()
    }

    /// Delete an event (manually cascading to guests + collection to avoid FK errors).
    func deleteEvent(eventId: UUID) async throws {
        // 1. Delete associated guest invites
        _ = try? await client.from("vip_event_guests").delete().eq("event_id", value: eventId).execute()
        
        // 2. Delete associated product collection
        _ = try? await client.from("vip_events_collection").delete().eq("event_id", value: eventId).execute()
        
        // 3. Delete the event itself
        try await client
            .from("vip_events")
            .delete()
            .eq("id", value: eventId)
            .execute()
    }

    // MARK: - vip_guests

    /// Fetch all VIP guests for a boutique.
    func fetchGuests(boutiqueId: UUID) async throws -> [VIPGuest] {
        let result: [VIPGuest] = try await client
            .from("vip_guests")
            .select("*")
            .eq("boutique_id", value: boutiqueId)
            .order("full_name", ascending: true)
            .execute()
            .value
        return result
    }

    /// Add a new VIP guest to the boutique directory.
    func addGuest(_ guest: VIPGuest) async throws {
        try await client
            .from("vip_guests")
            .insert(guest.insertPayload)
            .execute()
    }

    /// Delete a VIP guest from the directory.
    func deleteGuest(guestId: UUID) async throws {
        try await client
            .from("vip_guests")
            .delete()
            .eq("id", value: guestId)
            .execute()
    }

    // MARK: - vip_event_guests

    /// Fetch all event guest invitations for an event, joining guest details.
    func fetchEventGuests(eventId: UUID) async throws -> [VIPEventGuest] {
        let result: [VIPEventGuest] = try await client
            .from("vip_event_guests")
            .select("*, vip_guests(*)")
            .eq("event_id", value: eventId)
            .execute()
            .value
        return result
    }

    /// Invite a guest to an event.
    func inviteGuest(eventId: UUID, guestId: UUID) async throws {
        let payload = VIPEventGuest.InsertPayload(
            event_id:    eventId,
            guest_id:    guestId,
            rsvp_status: "invited"
        )
        try await client
            .from("vip_event_guests")
            .insert(payload)
            .execute()
    }

    /// Update RSVP status for an invite row.
    func updateRSVP(inviteId: UUID, status: String) async throws {
        try await client
            .from("vip_event_guests")
            .update(["rsvp_status": status])
            .eq("id", value: inviteId)
            .execute()
    }

    /// Remove a guest from an event.
    func removeEventGuest(inviteId: UUID) async throws {
        try await client
            .from("vip_event_guests")
            .delete()
            .eq("id", value: inviteId)
            .execute()
    }

    // MARK: - vip_events_collection

    /// Fetch the product collection for an event.
    func fetchCollection(eventId: UUID) async throws -> [VIPEventCollectionItem] {
        let result: [VIPEventCollectionItem] = try await client
            .from("vip_events_collection")
            .select("*")
            .eq("event_id", value: eventId)
            .order("display_order", ascending: true)
            .execute()
            .value
        return result
    }

    /// Add a product to an event's collection.
    func addToCollection(eventId: UUID, productId: UUID, order: Int, specialPrice: Double?) async throws {
        let payload = VIPEventCollectionItem.InsertPayload(
            event_id:      eventId,
            product_id:    productId,
            display_order: order,
            special_price: specialPrice,
            is_reserved:   false
        )
        try await client
            .from("vip_events_collection")
            .insert(payload)
            .execute()
    }

    /// Remove a product from the collection.
    func removeFromCollection(itemId: UUID) async throws {
        try await client
            .from("vip_events_collection")
            .delete()
            .eq("id", value: itemId)
            .execute()
    }

    /// Toggle `is_reserved` on a collection item.
    func toggleReserved(itemId: UUID, reserved: Bool) async throws {
        try await client
            .from("vip_events_collection")
            .update(["is_reserved": reserved])
            .eq("id", value: itemId)
            .execute()
    }

    // MARK: - vip_appointments

    /// Fetch all appointments for a boutique.
    func fetchAppointments(boutiqueId: UUID) async throws -> [VIPAppointment] {
        let result: [VIPAppointment] = try await client
            .from("vip_appointments")
            .select("*")
            .eq("boutique_id", value: boutiqueId)
            .order("appointment_date", ascending: true)
            .execute()
            .value
        return result
    }

    /// Create a new appointment.
    func createAppointment(_ payload: VIPAppointment.InsertPayload) async throws {
        try await client
            .from("vip_appointments")
            .insert(payload)
            .execute()
    }

    /// Update appointment status (scheduled -> completed/cancelled).
    func updateAppointmentStatus(appointmentId: UUID, status: String) async throws {
        try await client
            .from("vip_appointments")
            .update(["status": status])
            .eq("id", value: appointmentId)
            .execute()
    }
}
