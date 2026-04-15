//
//  Store.swift
//  Group5_RSMS
//
//  Sprint 1 — Core data model for boutique store locations.
//  Every feature in the system (inventory, staff, POS, reporting)
//  is scoped to a Store. This is the root of the data model.
//

import Foundation

struct Store: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var code: String              // e.g. "BTQ-MUM-001"
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
    var phone: String
    var email: String
    var managerName: String
    var region: String            // e.g. "West", "North", "South", "East"
    var taxRate: Double           // region-specific tax %
    var isActive: Bool = true
    var createdAt: Date = Date()

    // MARK: - Computed
    var formattedAddress: String {
        "\(address), \(city), \(state) \(zipCode), \(country)"
    }

    var formattedTaxRate: String {
        String(format: "%.1f%%", taxRate)
    }

    // MARK: - Sample Data
    static let sample = Store(
        name: "RSMS Flagship Mumbai",
        code: "BTQ-MUM-001",
        address: "123 Linking Road, Bandra West",
        city: "Mumbai",
        state: "Maharashtra",
        zipCode: "400050",
        country: "India",
        phone: "+91 22 2600 1234",
        email: "mumbai@rsms.com",
        managerName: "Priya Sharma",
        region: "West",
        taxRate: 18.0
    )

    static let samples: [Store] = [
        sample,
        Store(
            name: "RSMS Delhi Boutique",
            code: "BTQ-DEL-001",
            address: "45 Khan Market",
            city: "New Delhi",
            state: "Delhi",
            zipCode: "110003",
            country: "India",
            phone: "+91 11 2461 5678",
            email: "delhi@rsms.com",
            managerName: "Arjun Mehta",
            region: "North",
            taxRate: 18.0
        ),
        Store(
            name: "RSMS Bangalore Store",
            code: "BTQ-BLR-001",
            address: "78 MG Road, Indiranagar",
            city: "Bangalore",
            state: "Karnataka",
            zipCode: "560038",
            country: "India",
            phone: "+91 80 4567 8901",
            email: "bangalore@rsms.com",
            managerName: "Kavitha Rao",
            region: "South",
            taxRate: 18.0
        )
    ]
}
