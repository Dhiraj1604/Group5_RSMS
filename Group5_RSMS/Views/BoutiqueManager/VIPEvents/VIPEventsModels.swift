//
//  VIPEventsModels.swift
//  Group5_RSMS
//

import Foundation

// MARK: - VIP Client Models

struct VIPClient: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let tier: String // "Platinum", "Gold", "Silver"
    let totalSpend: Double
    let lastVisit: Date
    let preferences: [String]
    let birthday: Date?
    let anniversary: Date?
    
    // Derived property to check if a milestone is within the next 7 days
    var upcomingMilestone: String? {
        let calendar = Calendar.current
        let today = Date()
        
        if let bday = birthday, isUpcoming(date: bday, withinDays: 7, using: calendar, today: today) {
            return "Birthday in \(daysUntil(date: bday, using: calendar, today: today)) days"
        }
        if let anniv = anniversary, isUpcoming(date: anniv, withinDays: 7, using: calendar, today: today) {
            return "Anniversary in \(daysUntil(date: anniv, using: calendar, today: today)) days"
        }
        return nil
    }
    
    private func isUpcoming(date: Date, withinDays days: Int, using calendar: Calendar, today: Date) -> Bool {
        let currentYear = calendar.component(.year, from: today)
        guard let nextOccurrence = calendar.date(bySetting: .year, value: currentYear, of: date) else { return false }
        
        let finalOccurrence = nextOccurrence < today ? calendar.date(byAdding: .year, value: 1, to: nextOccurrence)! : nextOccurrence
        let daysDifference = calendar.dateComponents([.day], from: today, to: finalOccurrence).day ?? Int.max
        return daysDifference <= days && daysDifference >= 0
    }
    
    private func daysUntil(date: Date, using calendar: Calendar, today: Date) -> Int {
        let currentYear = calendar.component(.year, from: today)
        guard let nextOccurrence = calendar.date(bySetting: .year, value: currentYear, of: date) else { return 0 }
        let finalOccurrence = nextOccurrence < today ? calendar.date(byAdding: .year, value: 1, to: nextOccurrence)! : nextOccurrence
        return calendar.dateComponents([.day], from: today, to: finalOccurrence).day ?? 0
    }
}

struct VIPPurchase: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let itemName: String
    let sku: String
    let price: Double
    let purchaseDate: Date
}

// MARK: - VIP Events Models

struct VIPEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let capacity: Int
    var rsvps: [EventRSVP]
    let collectionDetails: [String] // e.g. ["Summer '26 Collection", "Limited Edition Watches"]
    
    var isFull: Bool {
        return rsvps.count >= capacity
    }
}

struct EventRSVP: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let clientName: String
    let rsvpDate: Date
}
