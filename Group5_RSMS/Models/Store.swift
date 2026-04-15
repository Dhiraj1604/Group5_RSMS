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
    
    // Local-only UI fields with defaults
    var code: String = "BTQ-NEW-001"
    var address: String = "123 Default Street"
    
    // DB synced fields
    var city: String
    var country: String
    var currencyCode: String
    
    // Local-only
    var state: String = "Default State"
    var zipCode: String = "00000"
    var phone: String = "+1 000 000 0000"
    var email: String = "contact@rsms.com"
    var managerName: String = "Store Manager"
    var region: String = "West"
    var taxRate: Double = 18.0
    var isActive: Bool = true
    
    // DB synced
    var createdAt: Date = Date()
    
    
    
    // MARK: - CodingKeys for Supabase (Read)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case city
        case country
        case currencyCode = "currency_code"
        case createdAt = "created_at"
    }

    // MARK: - Insert Payload for Supabase (Write)
    /// Excludes `id` and `created_at` which are handled by the DB via default rules.
    struct DBPayload: Encodable {
        let name: String
        let city: String
        let country: String
        let currency_code: String
    }
    
    var insertPayload: DBPayload {
        DBPayload(
            name: name,
            city: city,
            country: country,
            currency_code: currencyCode
        )
    }

    // MARK: - Computed
    var formattedAddress: String {
        "\(address), \(city), \(state) \(zipCode), \(country)"
    }

    var formattedTaxRate: String {
        String(format: "%.1f%%", taxRate)
    }

    // MARK: - Sample Data
    static let sample = Store(
        id: UUID(),
        name: "RSMS Flagship Mumbai",
        code: "BTQ-MUM-001",
        address: "123 Linking Road, Bandra West",
        city: "Mumbai",
        country: "India",
        currencyCode: "INR",
        state: "Maharashtra",
        zipCode: "400050",
        phone: "+91 22 2600 1234",
        email: "mumbai@rsms.com",
        managerName: "Priya Sharma",
        region: "West",
        taxRate: 18.0,
        isActive: true,
        createdAt: Date()
    )

    static let samples: [Store] = [
        sample,
        Store(
            id: UUID(),
            name: "RSMS Delhi Boutique",
            code: "BTQ-DEL-001",
            address: "45 Khan Market",
            city: "New Delhi",
            country: "India",
            currencyCode: "INR",
            state: "Delhi",
            zipCode: "110003",
            phone: "+91 11 2461 5678",
            email: "delhi@rsms.com",
            managerName: "Arjun Mehta",
            region: "North",
            taxRate: 18.0,
            isActive: true,
            createdAt: Date()
        ),
        Store(
            id: UUID(),
            name: "RSMS Bangalore Store",
            code: "BTQ-BLR-001",
            address: "78 MG Road, Indiranagar",
            city: "Bangalore",
            country: "India",
            currencyCode: "INR",
            state: "Karnataka",
            zipCode: "560038",
            phone: "+91 80 4567 8901",
            email: "bangalore@rsms.com",
            managerName: "Kavitha Rao",
            region: "South",
            taxRate: 18.0,
            isActive: true,
            createdAt: Date()
        )
    ]
}
