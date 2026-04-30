//
//  Store.swift
//  Group5_RSMS
//

import Foundation

struct Store: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    
    // DB synced fields
    var city: String
    var country: String
    var code: String = "BTQ-NEW-001"
    var phone: String? = nil
    var email: String? = nil
    var address: String? = nil
    var zipCode: String? = nil
    var state: String? = nil
    var managerName: String? = nil
    var region: String = "Asia"
    var taxRate: Double? = nil
    var isActive: Bool = true
    var currencyCode: String? = nil
    var monthlyRevenueTarget: Double? = nil
    var createdAt: Date? = Date()
    var assignedManagerId: UUID? = nil
    var imageUrl: String? = nil
    
    // MARK: - CodingKeys for Supabase (Read)
    // All DB columns are camelCase — no mapping needed except where Swift property differs.
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case city
        case country
        case code
        case phone
        case email
        case address
        case zipCode
        case state
        case managerName
        case region
        case taxRate
        case isActive
        case currencyCode
        case monthlyRevenueTarget = "monthly_revenue_target"
        case createdAt
        case assignedManagerId = "assigned_manager_id"
        case imageUrl = "image_url"
    }
    
    // MARK: - Insert Payload for Supabase (Write)
    /// Excludes `id` and `createdAt` which are handled by the DB via default rules.
    struct DBPayload: Encodable {
        let name: String
        let city: String
        let country: String
        let code: String
        let phone: String?
        let email: String?
        let address: String?
        let zipCode: String?
        let state: String?
        let managerName: String?
        let region: String?
        let taxRate: Double?
        let isActive: Bool?
        let currencyCode: String?
        let monthly_revenue_target: Double?
        let assigned_manager_id: UUID?
        let image_url: String?
    }
    
    var insertPayload: DBPayload {
        DBPayload(
            name: name,
            city: city,
            country: country,
            code: code,
            phone: phone,
            email: email,
            address: address,
            zipCode: zipCode,
            state: state,
            managerName: managerName,
            region: region,
            taxRate: taxRate,
            isActive: isActive,
            currencyCode: currencyCode,
            monthly_revenue_target: monthlyRevenueTarget,
            assigned_manager_id: assignedManagerId,
            image_url: imageUrl
        )
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
        city: "Mumbai",
        country: "India",
        code: "BTQ-MUM-001",
        phone: "+91 22 2600 1234",
        email: "mumbai@rsms.com",
        address: "123 Linking Road, Bandra West",
        zipCode: "400050",
        state: "Maharashtra",
        managerName: "Priya Sharma",
        region: "West",
        taxRate: 18.0,
        isActive: true,
        imageUrl: "image_1"
    )
        
    static let samples: [Store] = [
        sample,
        Store(
            name: "RSMS Delhi Boutique",
            city: "New Delhi",
            country: "India",
            code: "BTQ-DEL-001",
            phone: "+91 11 2461 5678",
            email: "delhi@rsms.com",
            address: "45 Khan Market",
            zipCode: "110003",
            state: "Delhi",
            managerName: "Arjun Mehta",
            region: "North",
            taxRate: 18.0,
            isActive: true,
            currencyCode: "INR",
            createdAt: Date(),
            imageUrl: "image_2"
        ),
        Store(
            name: "Dior Dubai Mall",
            city: "Dubai",
            country: "UAE",
            code: "BTQ-DXB-001",
            phone: "+971 4 330 8739",
            email: "dubai@dior.com",
            address: "The Dubai Mall, Fashion Avenue",
            zipCode: "00000",
            state: "Dubai",
            managerName: "Omar Hassan",
            region: "MEIA",
            taxRate: 5.0,
            isActive: true,
            currencyCode: "AED",
            monthlyRevenueTarget: 1500000.0,
            imageUrl: "Dior Dubai Mall"
        ),
        Store(
            name: "RSMS Bangalore Store",
            city: "Bangalore",
            country: "India",
            code: "BTQ-BLR-001",
            phone: "+91 80 4567 8901",
            email: "bangalore@rsms.com",
            address: "78 MG Road, Indiranagar",
            zipCode: "560038",
            state: "Karnataka",
            managerName: "Kavitha Rao",
            region: "South",
            taxRate: 18.0,
            isActive: true,
            currencyCode: "INR",
            createdAt: Date(),
            imageUrl: "image_3"
        ),
        Store(
            name: "RSMS London Gallery",
            city: "London",
            country: "UK",
            code: "BTQ-LON-001",
            phone: "+44 20 7946 0000",
            email: "london@rsms.com",
            address: "15 Bond Street",
            zipCode: "W1S 3SU",
            state: "London",
            managerName: "Emma Watson",
            region: "Europe",
            taxRate: 20.0,
            isActive: true,
            currencyCode: "GBP",
            createdAt: Date(),
            imageUrl: "image_4"
        )
    ]
}
