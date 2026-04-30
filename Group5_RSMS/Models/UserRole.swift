//
//  UserRole.swift
//  Group5_RSMS
//
//

import SwiftUI

enum UserRole: String, CaseIterable, Identifiable, Codable {
    case corporateAdmin = "admin"
    case boutiqueManager = "manager"
    case inventoryController = "inventory"

    var id: String { rawValue }

    var displayName: String { 
        switch self {
        case .corporateAdmin: return "Corporate Admin"
        case .boutiqueManager: return "Boutique Manager"
        case .inventoryController: return "Inventory Controller"
        }
    }

    var description: String {
        switch self {
        case .corporateAdmin:
            return "Oversee all stores, products, pricing, offers, and company-wide analytics."
        case .boutiqueManager:
            return "Manage daily operations, staff, and sales for your assigned boutique."
        case .inventoryController:
            return "Track stock levels, handle shipments, and manage warehouse operations."
        }
    }

    var icon: String {
        switch self {
        case .corporateAdmin:
            return "building.2.fill"
        case .boutiqueManager:
            return "storefront.fill"
        case .inventoryController:
            return "shippingbox.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .corporateAdmin:
            return Color(hue: 0.08, saturation: 0.8, brightness: 0.95)   // Gold
        case .boutiqueManager:
            return Color(hue: 0.55, saturation: 0.6, brightness: 0.9)    // Teal
        case .inventoryController:
            return Color(hue: 0.75, saturation: 0.5, brightness: 0.85)   // Purple
        }
    }
}
