//
//  VIPEventsViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

@MainActor
class VIPEventsViewModel: ObservableObject {
    @Published var vipClients: [VIPClient] = []
    @Published var events: [VIPEvent] = []
    
    // Purchases mapped by client ID
    @Published var purchases: [UUID: [VIPPurchase]] = [:]
    
    init() {
        loadMockData()
    }
    
    // MARK: - Event Management
    
    func createEvent(title: String, date: Date, capacity: Int, collections: [String]) {
        let newEvent = VIPEvent(
            id: UUID(),
            title: title,
            date: date,
            capacity: capacity,
            rsvps: [],
            collectionDetails: collections
        )
        events.append(newEvent)
        events.sort { $0.date < $1.date }
    }
    
    func rsvpForEvent(eventId: UUID, clientName: String) -> Bool {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return false }
        
        var event = events[index]
        if event.isFull { return false } // Prevent RSVP if full
        
        let newRSVP = EventRSVP(id: UUID(), eventId: eventId, clientName: clientName, rsvpDate: Date())
        event.rsvps.append(newRSVP)
        events[index] = event
        return true
    }
    
    // MARK: - Mock Data Setup
    
    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Mock VIPs
        let vip1 = VIPClient(
            id: UUID(), name: "Isabella Rossi", email: "isabella.r@example.com", phone: "+1 555-0101",
            tier: "Platinum", totalSpend: 145000.0, lastVisit: calendar.date(byAdding: .day, value: -12, to: today)!,
            preferences: ["Fine Jewelry", "Rose Gold", "Exclusive Previews"],
            birthday: calendar.date(byAdding: .day, value: 4, to: today)!, // Upcoming birthday!
            anniversary: nil
        )
        
        let vip2 = VIPClient(
            id: UUID(), name: "Alexander Chen", email: "achen.vip@example.com", phone: "+1 555-0102",
            tier: "Gold", totalSpend: 68000.0, lastVisit: calendar.date(byAdding: .day, value: -45, to: today)!,
            preferences: ["Chronograph Watches", "Leather Accessories"],
            birthday: calendar.date(byAdding: .month, value: 3, to: today)!,
            anniversary: calendar.date(byAdding: .day, value: 2, to: today)! // Upcoming anniversary!
        )
        
        let vip3 = VIPClient(
            id: UUID(), name: "Sophia Laurent", email: "sophia.l@example.com", phone: "+1 555-0103",
            tier: "Platinum", totalSpend: 210000.0, lastVisit: calendar.date(byAdding: .day, value: -5, to: today)!,
            preferences: ["Haute Couture", "Limited Editions", "Evening Wear"],
            birthday: calendar.date(byAdding: .month, value: -2, to: today)!,
            anniversary: nil
        )
        
        vipClients = [vip1, vip2, vip3]
        
        // Mock Purchases
        purchases[vip1.id] = [
            VIPPurchase(id: UUID(), clientId: vip1.id, itemName: "Rose Gold Diamond Necklace", sku: "JW-RG-001", price: 45000.0, purchaseDate: calendar.date(byAdding: .day, value: -12, to: today)!),
            VIPPurchase(id: UUID(), clientId: vip1.id, itemName: "Sapphire Earrings", sku: "JW-SP-002", price: 22000.0, purchaseDate: calendar.date(byAdding: .day, value: -120, to: today)!)
        ]
        
        purchases[vip2.id] = [
            VIPPurchase(id: UUID(), clientId: vip2.id, itemName: "Classic Chronograph Watch", sku: "WT-CC-105", price: 35000.0, purchaseDate: calendar.date(byAdding: .day, value: -45, to: today)!)
        ]
        
        // Mock Events
        let event1 = VIPEvent(
            id: UUID(), title: "Summer '26 Exclusive Preview", 
            date: calendar.date(byAdding: .day, value: 10, to: today)!, 
            capacity: 25, rsvps: [], 
            collectionDetails: ["Summer '26 Ready-to-Wear", "Resort Accessories"]
        )
        
        let event2 = VIPEvent(
            id: UUID(), title: "Private Watch Masterclass", 
            date: calendar.date(byAdding: .day, value: 3, to: today)!, 
            capacity: 2, rsvps: [
                EventRSVP(id: UUID(), eventId: UUID(), clientName: "Alexander Chen", rsvpDate: today)
            ], 
            collectionDetails: ["Heritage Timepieces", "2026 Chronograph Line"]
        )
        
        events = [event1, event2].sorted { $0.date < $1.date }
    }
}
