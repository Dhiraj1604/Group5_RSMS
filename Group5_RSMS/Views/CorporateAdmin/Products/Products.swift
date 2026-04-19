//
//  Product.swift
//  Group5_RSMS
//
//  Sprint 1 — Task #2 (Centralised Product & Pricing Engine)  — Dhiraj / Zeeshan
//             Task #4 (Set Official Retail Price)             — Dhiraj
//             Task #5 (Material, Origin & Craftsmanship)      — Zeeshan
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

struct ProductNew: Identifiable, Codable, Equatable, Hashable {

    // ── Core Identity ──────────────────────────────────────────────
    var id: UUID = UUID()
    var sku: String
    var name: String
    var imageUrl: String?
    var category: ProductCategory = .other
    var isActive: Bool = true
    var isGloballyListed: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // ── Pricing (Task #2 / #4 — Dhiraj) ───────────────────────────
    var basePrice: Double = 0

    // ── Craftsmanship & Heritage (Task #5 — Zeeshan) ───────────────
    var material: String = ""
    var originCountry: String = ""
    var craftsmanshipLevel: CraftsmanshipLevel = .handcrafted
    var craftsmanshipNotes: String = ""
    var collectionName: String = ""
    var artisanStudio: String = ""

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case name
        case category
        case isActive           = "is_active"
        case isGloballyListed   = "is_globally_listed"
        case createdAt          = "created_at"
        case updatedAt          = "updated_at"
        case basePrice          = "base_price"
        case material
        case imageUrl           = "image_url"
        case originCountry      = "origin_country"
        case craftsmanshipLevel = "craftsmanship_level"
        case craftsmanshipNotes = "craftsmanship_notes"
        case collectionName     = "collection_name"
        case artisanStudio      = "artisan_studio"
    }

    // MARK: - Computed

    var formattedPrice: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.currencySymbol = "₹"
        return f.string(from: NSNumber(value: basePrice)) ?? "₹\(basePrice)"
    }

    var statusBadge: String {
        if !isActive { return "Inactive" }
        if !isGloballyListed { return "Unlisted" }
        return "Active"
    }

    // Equatable & Hashable — identity-based
    static func == (lhs: ProductNew, rhs: ProductNew) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Sample Data

    static let sample = ProductNew(
        sku: "JWL-RNG-001",
        name: "Maharaja Diamond Ring",
        category: .jewellery,
        basePrice: 485000,
        material: "18K Yellow Gold, VS1 Diamonds (2.4ct total)",
        originCountry: "India",
        craftsmanshipLevel: .handcrafted,
        craftsmanshipNotes: "Hand-set diamonds by master craftsmen in Jaipur with 40+ years of heritage.",
        collectionName: "Maharaja Heritage 2025",
        artisanStudio: "Atelier Jaipur"
    )

    static let samples: [ProductNew] = [
        sample,
        ProductNew(
            sku: "WTC-CHR-001", name: "Chronograph Prestige", category: .watches,
            basePrice: 1250000,
            material: "Grade 5 Titanium, Sapphire Crystal", originCountry: "Switzerland",
            craftsmanshipLevel: .maison,
            craftsmanshipNotes: "Swiss lever escapement with 72-hour power reserve.",
            collectionName: "Prestige Tourbillon", artisanStudio: "Manufacture Geneva"
        ),
        ProductNew(
            sku: "LTH-BAG-003", name: "Midnight Tote", category: .leatherGoods,
            isGloballyListed: false, basePrice: 95000,
            material: "Full-Grain Nappa Leather, 24K Gold Hardware", originCountry: "Italy",
            craftsmanshipLevel: .handFinished,
            craftsmanshipNotes: "Vegetable-tanned in Tuscany, hand-stitched using saddle stitch.",
            collectionName: "Notte Collection", artisanStudio: "Pelletteria Firenze"
        ),
        ProductNew(
            sku: "COU-GWN-007", name: "Evening Cascade Gown", category: .couture,
            isActive: false, isGloballyListed: false, basePrice: 320000,
            material: "Duchess Silk Satin, Swarovski Embellishments", originCountry: "France",
            craftsmanshipLevel: .bespoke,
            craftsmanshipNotes: "300+ hours of hand embroidery by Paris couture house.",
            collectionName: "Lumière Autumn/Winter", artisanStudio: "Maison de Couture Paris"
        )
    ]
}
