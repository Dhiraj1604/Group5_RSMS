//
//  Store.swift
//  Group5_RSMS
//

import Foundation

struct Store: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
   var name: String
   var code: String = "BTQ-NEW-001"
   var address: String? = nil          // was String = ""
   var city: String
   var country: String
   var currencyCode: String? = nil     // was String
   var state: String? = nil            // was String = ""
   var zipCode: String? = nil          // was String = ""
   var phone: String? = nil            // was String = ""
   var email: String? = nil            // was String = ""
   var managerName: String? = nil      // was String = ""
   var region: String = "West"
   var taxRate: Double? = nil          // was Double = 18.0
   var isActive: Bool = true
   var createdAt: Date = Date()
   var assignedManagerId: UUID? = nil


    enum CodingKeys: String, CodingKey {
        case id, name, code, address, city, country,
             state, region, phone, email,
             currencyCode, zipCode, managerName,
             taxRate, isActive, createdAt
        case assignedManagerId = "assigned_manager_id"
    }

    // MARK: - Computed
    var formattedAddress: String {
        "\(address ?? ""), \(city), \(state ?? "") \(zipCode ?? ""), \(country)"
    }

    var formattedTaxRate: String {
        String(format: "%.1f%%", taxRate ?? 0.0)
    }


    // MARK: - Sample Data
    static let sample = Store(
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
        isActive: true
    )

    static let samples: [Store] = [
        sample,
        Store(
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
            isActive: true
        ),
        Store(
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
            isActive: true
        )
    ]
}
