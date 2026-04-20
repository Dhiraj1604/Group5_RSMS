//
//  PricingModels.swift
//  Group5_RSMS
//
//  Core/Pricing
//

import Foundation

/// Represents a retail product in the inventory.
struct Product: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Core Identity
    var id: UUID
    var sku: String
    var name: String
    var imageUrl: String?
    var category: ProductCategory
    var isActive: Bool
    var isGloballyListed: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Pricing
    var basePrice: Double

    // MARK: - Craftsmanship & Heritage
    var material: String
    var originCountry: String
    var craftsmanshipLevel: CraftsmanshipLevel
    var craftsmanshipNotes: String
    var collectionName: String
    var artisanStudio: String
    var inRepair: Bool

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case name
        case imageUrl           = "image_url"
        case category
        case isActive           = "is_active"
        case isGloballyListed   = "is_globally_listed"
        case createdAt          = "created_at"
        case updatedAt          = "updated_at"
        case basePrice          = "base_price"
        case material
        case originCountry      = "origin_country"
        case craftsmanshipLevel = "craftsmanship_level"
        case craftsmanshipNotes = "craftsmanship_notes"
        case collectionName     = "collection_name"
        case artisanStudio      = "artisan_studio"
        case inRepair           = "in_repair"
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        sku: String,
        name: String,
        imageUrl: String? = nil,
        category: ProductCategory = .other,
        isActive: Bool = true,
        isGloballyListed: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        basePrice: Double = 0,
        material: String = "",
        originCountry: String = "",
        craftsmanshipLevel: CraftsmanshipLevel = .handcrafted,
        craftsmanshipNotes: String = "",
        collectionName: String = "",
        artisanStudio: String = "",
        inRepair: Bool = false
    ) {
        self.id = id
        self.sku = sku
        self.name = name
        self.imageUrl = imageUrl
        self.category = category
        self.isActive = isActive
        self.isGloballyListed = isGloballyListed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.basePrice = basePrice
        self.material = material
        self.originCountry = originCountry
        self.craftsmanshipLevel = craftsmanshipLevel
        self.craftsmanshipNotes = craftsmanshipNotes
        self.collectionName = collectionName
        self.artisanStudio = artisanStudio
        self.inRepair = inRepair
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

    // MARK: - Equatable
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id &&
        lhs.sku == rhs.sku &&
        lhs.name == rhs.name &&
        lhs.basePrice == rhs.basePrice &&
        lhs.isActive == rhs.isActive &&
        lhs.isGloballyListed == rhs.isGloballyListed &&
        lhs.imageUrl == rhs.imageUrl &&
        lhs.category == rhs.category &&
        lhs.material == rhs.material &&
        lhs.originCountry == rhs.originCountry &&
        lhs.craftsmanshipLevel == rhs.craftsmanshipLevel &&
        lhs.inRepair == rhs.inRepair
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Sample Data
    static let sample = Product(
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

    static let samples: [Product] = [
        sample,
        Product(
            sku: "WTC-CHR-001", name: "Chronograph Prestige", category: .watches,
            basePrice: 1250000,
            material: "Grade 5 Titanium, Sapphire Crystal", originCountry: "Switzerland",
            craftsmanshipLevel: .maison,
            craftsmanshipNotes: "Swiss lever escapement with 72-hour power reserve.",
            collectionName: "Prestige Tourbillon", artisanStudio: "Manufacture Geneva"
        ),
        Product(
            sku: "LTH-BAG-003", name: "Midnight Tote", category: .leatherGoods,
            isGloballyListed: false, basePrice: 95000,
            material: "Full-Grain Nappa Leather, 24K Gold Hardware", originCountry: "Italy",
            craftsmanshipLevel: .handFinished,
            craftsmanshipNotes: "Vegetable-tanned in Tuscany, hand-stitched using saddle stitch.",
            collectionName: "Notte Collection", artisanStudio: "Pelletteria Firenze"
        ),
        Product(
            sku: "COU-GWN-007", name: "Evening Cascade Gown", category: .couture,
            isActive: false, isGloballyListed: false, basePrice: 320000,
            material: "Duchess Silk Satin, Swarovski Embellishments", originCountry: "France",
            craftsmanshipLevel: .bespoke,
            craftsmanshipNotes: "300+ hours of hand embroidery by Paris couture house.",
            collectionName: "Lumière Autumn/Winter", artisanStudio: "Maison de Couture Paris"
        )
    ]
}

// MARK: - TaxRule

/// Defines a regional tax rule aligned with the `tax_rules` Supabase table.
struct TaxRule: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var rate: Double
    var isInclusive: Bool
    var storeId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rate
        case isInclusive = "is_inclusive"
        case storeId     = "store_id"
    }

    struct DBPayload: Encodable {
        let name: String
        let rate: Double
        let is_inclusive: Bool
        let store_id: UUID
    }

    var dbPayload: DBPayload {
        DBPayload(
            name: name,
            rate: rate,
            is_inclusive: isInclusive,
            store_id: storeId
        )
    }

    init(
        id: UUID = UUID(),
        name: String,
        rate: Double,
        isInclusive: Bool,
        storeId: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.rate = rate
        self.isInclusive = isInclusive
        self.storeId = storeId
    }
}

// MARK: - PricingBreakdown

/// The result format of a pricing calculation.
struct PricingBreakdown: Equatable, Hashable {
    let subtotal: Double
    let taxAmount: Double
    let total: Double

    init(subtotal: Double, taxAmount: Double, total: Double) {
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.total = total
    }
}
