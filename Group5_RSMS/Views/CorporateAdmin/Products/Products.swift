//
//  Product.swift
//  Group5_RSMS
//
//
//  Supabase table: `products`
//

import Foundation

// MARK: - Supporting Enumerations

enum ProductCategory: String, CaseIterable, Codable, Identifiable, Equatable {
    case jewellery    = "Jewellery"
    case watches      = "Watches"
    case leatherGoods = "Leather Goods"
    case couture      = "Couture"
    case accessories  = "Accessories"
    case fragrance    = "Fragrance"
    case eyewear      = "Eyewear"
    case other        = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .jewellery:    return "sparkles"
        case .watches:      return "clock.fill"
        case .leatherGoods: return "bag.fill"
        case .couture:      return "tshirt.fill"
        case .accessories:  return "eyeglasses"
        case .fragrance:    return "wind"
        case .eyewear:      return "eyeglasses"
        case .other:        return "tag.fill"
        }
    }
}

enum CraftsmanshipLevel: String, CaseIterable, Codable, Equatable {
    case handcrafted    = "Handcrafted"
    case handFinished   = "Hand-Finished"
    case limitedEdition = "Limited Edition"
    case maison         = "Maison Exclusive"
    case bespoke        = "Bespoke"
    case readyToWear    = "Ready-to-Wear"
}

// MARK: - Product Model
//
// The unified `Product` struct now lives in Core/Pricing/PricingModels.swift.
// It is the single source of truth for all product CRUD and Supabase operations.
//
