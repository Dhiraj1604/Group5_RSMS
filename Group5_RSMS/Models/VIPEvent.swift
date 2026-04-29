//
//  VIPEvent.swift
//  Group5_RSMS
//
//  Models for the VIP Events feature.
//  Tables: vip_events, vip_guests, vip_event_guests, vip_events_collection
//

import Foundation

// MARK: - VIPEvent

struct VIPEvent: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    var title: String
    var description: String?
    var eventDate: Date?
    var guestCapacity: Int?
    var venue: String?
    var status: String         // upcoming | ongoing | completed | cancelled
    var hostEmployeeId: UUID?
    var theme: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId      = "boutique_id"
        case title
        case description
        case eventDate       = "event_date"
        case guestCapacity   = "guest_capacity"
        case venue
        case status
        case hostEmployeeId  = "host_employee_id"
        case theme
        case createdAt       = "created_at"
    }

    // MARK: - Insert payload (excludes id & created_at — set by DB)
    struct InsertPayload: Encodable {
        let id: UUID
        let boutique_id: UUID          // UUID type — Supabase handles FK correctly
        let title: String
        let description: String?
        let event_date: String?
        let guest_capacity: Int?
        let venue: String?
        let status: String
        let host_employee_id: UUID?
        let theme: String?
    }

    var insertPayload: InsertPayload {
        let iso = ISO8601DateFormatter()
        return InsertPayload(
            id:               id,
            boutique_id:      boutiqueId,
            title:            title,
            description:      description,
            event_date:       eventDate.map { iso.string(from: $0) },
            guest_capacity:   guestCapacity,
            venue:            venue,
            status:           status,
            host_employee_id: hostEmployeeId,
            theme:            theme
        )
    }

    // MARK: - Derived helpers
    var statusDisplay: String {
        switch status.lowercased() {
        case "upcoming":   return "Upcoming"
        case "completed":  return "Completed"
        case "cancelled":  return "Cancelled"
        default:           return status.capitalized
        }
    }

    var isEditable: Bool {
        status == "upcoming" 
    }

    var formattedDate: String {
        guard let d = eventDate else { return "TBD" }
        return d.formatted(.dateTime.day().month(.wide).year().hour().minute())
    }
}

// MARK: - VIPGuest (boutique's VIP customer directory)

struct VIPGuest: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    var fullName: String
    var email: String?
    var phone: String?
    var addedBy: UUID?
    var preferences: String?
    var lastVisit: Date?
    let createdBy: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId  = "boutique_id"
        case fullName    = "full_name"
        case email
        case phone
        case addedBy     = "added_by"
        case preferences
        case lastVisit   = "last_visit"
        case createdBy   = "created_by"
    }

    // MARK: - Insert payload
    struct InsertPayload: Encodable {
        let id: UUID
        let boutique_id: UUID          // UUID type — matches stores(id) FK
        let full_name: String
        let email: String?
        let phone: String?
        let preferences: String?
        let last_visit: String?
        let added_by: UUID?
    }

    var insertPayload: InsertPayload {
        let iso = ISO8601DateFormatter()
        return InsertPayload(
            id:          id,
            boutique_id: boutiqueId,
            full_name:   fullName,
            email:       email,
            phone:       phone,
            preferences: preferences,
            last_visit:  lastVisit.map { iso.string(from: $0) },
            added_by:    addedBy
        )
    }



    var initials: String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last  = parts.dropFirst().first?.prefix(1) ?? ""
        return (first + last).uppercased()
    }
}

// MARK: - VIPEventGuest (invite record per event)

struct VIPEventGuest: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let guestId: UUID?
    var rsvpStatus: String?    // invited | confirmed | declined | attended | no_show
    var invitedAt: Date?
    var notes: String?

    // Joined guest info (when queried with vip_guests(*))
    var guest: VIPGuest?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId     = "event_id"
        case guestId     = "guest_id"
        case rsvpStatus  = "rsvp_status"
        case invitedAt   = "invited_at"
        case notes
        case guest       = "vip_guests"
    }

    struct InsertPayload: Encodable {
        let event_id: UUID
        let guest_id: UUID
        let rsvp_status: String
    }
}

// MARK: - VIPEventCollectionItem (product showcase per event)

struct VIPEventCollectionItem: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let productId: UUID?
    var displayOrder: Int?
    var specialPrice: Double?
    var isReserved: Bool?
    var addedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId      = "event_id"
        case productId    = "product_id"
        case displayOrder = "display_order"
        case specialPrice = "special_price"
        case isReserved   = "is_reserved"
        case addedAt      = "added_at"
    }

    struct InsertPayload: Encodable {
        let event_id: UUID
        let product_id: UUID
        let display_order: Int
        let special_price: Double?
        let is_reserved: Bool
    }
}

// MARK: - VIP Appointment

struct VIPAppointment: Codable, Identifiable {
    let id: UUID
    let guestId: UUID
    let boutiqueId: UUID
    var title: String?
    var appointmentDate: Date
    var type: String         // e.g., "In-Store Styling", "Virtual Consultation", "Repair/Service"
    var status: String       // e.g., "scheduled", "completed", "cancelled"
    var notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case guestId         = "guest_id"
        case boutiqueId      = "boutique_id"
        case title
        case appointmentDate = "appointment_date"
        case type
        case status
        case notes
        case createdAt       = "created_at"
    }

    struct InsertPayload: Encodable {
        let guest_id: UUID
        let boutique_id: UUID
        let title: String?
        let appointment_date: Date
        let type: String
        let status: String
        let notes: String?
    }
}
