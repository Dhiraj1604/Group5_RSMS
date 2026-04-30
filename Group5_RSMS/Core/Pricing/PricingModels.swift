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

    // MARK: - Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required Identity
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.sku = try container.decodeIfPresent(String.self, forKey: .sku) ?? "UNKNOWN-SKU"
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unnamed Product"
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)

        // Core Status & Metadata
        self.category = try container.decodeIfPresent(ProductCategory.self, forKey: .category) ?? .other
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        self.isGloballyListed = try container.decodeIfPresent(Bool.self, forKey: .isGloballyListed) ?? true

        // Helper to parse dates dynamically
        let parseDate: (String) -> Date? = { str in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            
            let formatter2 = ISO8601DateFormatter()
            if let date = formatter2.date(from: str) { return date }
            
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
            if let date = df.date(from: str) { return date }
            
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = df.date(from: str) { return date }
            
            return nil
        }

        // Dates (Handling potential format issues)
        if let createdAtString = try? container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = parseDate(createdAtString) {
            self.createdAt = date
        } else {
            self.createdAt = (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ?? Date()
        }

        if let updatedAtString = try? container.decodeIfPresent(String.self, forKey: .updatedAt),
           let date = parseDate(updatedAtString) {
            self.updatedAt = date
        } else {
            self.updatedAt = (try? container.decodeIfPresent(Date.self, forKey: .updatedAt)) ?? Date()
        }

        // Pricing
        if let price = try? container.decodeIfPresent(Double.self, forKey: .basePrice) {
            self.basePrice = price
        } else if let priceStr = try? container.decodeIfPresent(String.self, forKey: .basePrice), let price = Double(priceStr) {
            self.basePrice = price
        } else {
            self.basePrice = 0
        }

        // Craftsmanship & Heritage (Providing defaults if missing from legacy records)
        self.material = try container.decodeIfPresent(String.self, forKey: .material) ?? "Not Specified"
        self.originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry) ?? "N/A"
        self.craftsmanshipLevel = try container.decodeIfPresent(CraftsmanshipLevel.self, forKey: .craftsmanshipLevel) ?? .handcrafted
        self.craftsmanshipNotes = try container.decodeIfPresent(String.self, forKey: .craftsmanshipNotes) ?? ""
        self.collectionName = try container.decodeIfPresent(String.self, forKey: .collectionName) ?? "General Catalogue"
        self.artisanStudio = try container.decodeIfPresent(String.self, forKey: .artisanStudio) ?? ""
        self.inRepair = try container.decodeIfPresent(Bool.self, forKey: .inRepair) ?? false
    }

    // MARK: - Computed
    var formattedPrice: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "INR"
        f.currencySymbol = "₹"
        f.maximumFractionDigits = basePrice.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
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
        sku: "JWL-PN-002",
        name: "Imperial Emerald Pendant",
        category: .jewellery,
        basePrice: 620000,
        material: "18K White Gold, Colombian Emerald (3.2ct)",
        originCountry: "Colombia",
        craftsmanshipLevel: .maison,
        craftsmanshipNotes: "A masterpiece of gem-setting and engraving.",
        collectionName: "Emerald Heritage",
        artisanStudio: "Atelier Paris"
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
        )
    ]
}

// MARK: - TaxRule

/// Defines an additional category-based tax rule.
struct TaxRule: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var rate: Double
    var category: ProductCategory

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rate
        case category
    }

    struct DBPayload: Encodable {
        let name: String
        let rate: Double
        let category: String
    }

    var dbPayload: DBPayload {
        DBPayload(
            name: name,
            rate: rate,
            category: category.rawValue
        )
    }

    init(
        id: UUID = UUID(),
        name: String,
        rate: Double,
        category: ProductCategory = .other
    ) {
        self.id = id
        self.name = name
        self.rate = rate
        self.category = category
    }
}

// MARK: - PricingBreakdown

/// The result format of a pricing calculation.
struct PricingBreakdown: Equatable, Hashable {
    let subtotal: Double
    let additionalTaxAmount: Double
    let taxAmount: Double
    let total: Double

    init(subtotal: Double, additionalTaxAmount: Double, total: Double) {
        self.subtotal = subtotal
        self.additionalTaxAmount = additionalTaxAmount
        self.taxAmount = additionalTaxAmount
        self.total = total
    }
}
