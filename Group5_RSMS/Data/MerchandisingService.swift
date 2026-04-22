//
//  MerchandisingService.swift
//  Group5_RSMS
//
//  Service for fetching merchandising insights and sales data from Supabase.
//

import Foundation
import Supabase

final class MerchandisingService {
    
    static let shared = MerchandisingService()
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Total Sales (Sold Products)
    
    /// Fetches products sold for a specific store in the current month.
    func fetchSoldProducts(forStore storeId: UUID) async throws -> [SoldProduct] {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: startOfMonth)
        
        let response = try await client
            .from("customer_orders")
            .select("*, customer_order_items(*, products(sku, image_url))")
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateString)
            .execute()
            
        let orders = try decoder.decode([OrderWithItems].self, from: response.data)
        
        var productMap: [UUID: SoldProduct] = [:]
        
        for order in orders {
            for item in order.customer_order_items ?? [] {
                let pid = item.product_id
                let effectiveImageUrl = item.product_image_url ?? item.products?.image_url
                let effectiveSku = item.products?.sku ?? "N/A"
                
                let current = productMap[pid] ?? SoldProduct(
                    id: pid,
                    name: item.product_name,
                    sku: effectiveSku,
                    imageUrl: effectiveImageUrl,
                    quantitySold: 0,
                    totalRevenue: 0
                )
                
                productMap[pid] = SoldProduct(
                    id: pid,
                    name: current.name,
                    sku: current.sku,
                    imageUrl: current.imageUrl,
                    quantitySold: current.quantitySold + item.quantity,
                    totalRevenue: current.totalRevenue + (item.price_at_purchase * Double(item.quantity))
                )
            }
        }
        
        return Array(productMap.values).sorted(by: { $0.quantitySold > $1.quantitySold })
    }
    
    // MARK: - Fallback Items
    
    /// Fetches items that have been on the sales floor for more than 30 days.
    func fetchFallbackItems(forStore storeId: UUID) async throws -> [InventoryProduct] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: thirtyDaysAgo)
        
        // We now query 'inventory' table joined with 'products'
        // This allows different stores to have different floor dates for the same product
        struct InventoryJoin: Decodable {
            let is_on_floor: Bool
            let last_moved_to_floor: Date?
            let products: InventoryProduct // The product details nested
        }
        
        let response = try await client
            .from("inventory")
            .select("is_on_floor, last_moved_to_floor, products(*)")
            .eq("store_id", value: storeId)
            .eq("is_on_floor", value: true)
            .lt("last_moved_to_floor", value: dateString)
            .execute()
            
        let joinedItems = try decoder.decode([InventoryJoin].self, from: response.data)
        
        // Flatten the results into InventoryProduct objects for the UI
        return joinedItems.map { join in
            // We return a 'copy' of the product but with the store-specific dates
            // Note: InventoryProduct is a struct, so we can modify a local copy
            let p = join.products
            return InventoryProduct(
                id: p.id,
                sku: p.sku,
                name: p.name,
                description: p.description,
                base_Price: p.base_Price,
                category_id: p.category_id,
                image_Url: p.image_Url,
                created_at: p.created_at,
                inRepair: p.inRepair,
                is_on_floor: join.is_on_floor,
                last_moved_to_floor: join.last_moved_to_floor
            )
        }
    }
    
    // MARK: - Weekly Sales Trend
    
    /// Fetches daily sales totals for the last 7 days.
    func fetchWeeklySalesTrend(forStore storeId: UUID) async throws -> [SalesTrendData] {
        let calendar = Calendar.current
        let now = Date()
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else {
            return []
        }
        
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: sevenDaysAgo)
        
        struct OrderRevenue: Decodable {
            let total_amount: Double
            let created_at: Date
        }
        
        let response = try await client
            .from("customer_orders")
            .select("total_amount, created_at")
            .eq("store_id", value: storeId)
            .gte("created_at", value: dateString)
            .order("created_at", ascending: true)
            .execute()
            
        let orders = try decoder.decode([OrderRevenue].self, from: response.data)
            
        // Initialize dailyTotals for the last 7 days
        var dailyTotals: [Date: Double] = [:]
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: now)) {
                dailyTotals[date] = 0
            }
        }
        
        // Group orders by their start-of-day
        for order in orders {
            let orderDay = calendar.startOfDay(for: order.created_at)
            if dailyTotals[orderDay] != nil {
                dailyTotals[orderDay]! += order.total_amount
            }
        }
        
        // Map back to SalesTrendData and sort by date
        return dailyTotals.map { (date, amount) in
            SalesTrendData(date: date, amount: amount)
        }.sorted(by: { $0.date < $1.date })
    }
}

// MARK: - Helper Structures for Decoding

private struct OrderWithItems: Decodable {
    let id: UUID
    let created_at: Date
    let customer_order_items: [OrderItem]?
    
    enum CodingKeys: String, CodingKey {
        case id, created_at, customer_order_items
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.created_at = try container.decodeIfPresent(Date.self, forKey: .created_at) ?? Date()
        self.customer_order_items = try container.decodeIfPresent([OrderItem].self, forKey: .customer_order_items)
    }
}

private struct OrderItem: Decodable {
    let product_id: UUID
    let product_name: String
    let product_image_url: String?
    let quantity: Int
    let price_at_purchase: Double
    let products: ProductInfo? // Nested info from join
    
    struct ProductInfo: Decodable {
        let sku: String?
        let image_url: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case product_id, product_name, product_image_url, quantity, price_at_purchase, products
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.product_id = try container.decodeIfPresent(UUID.self, forKey: .product_id) ?? UUID()
        self.product_name = try container.decodeIfPresent(String.self, forKey: .product_name) ?? "Unknown Product"
        self.product_image_url = try container.decodeIfPresent(String.self, forKey: .product_image_url)
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 0
        self.price_at_purchase = try container.decodeIfPresent(Double.self, forKey: .price_at_purchase) ?? 0.0
        self.products = try container.decodeIfPresent(ProductInfo.self, forKey: .products)
    }
}

extension MerchandisingService {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = formatter.date(from: dateStr) { return date }
            if let date = ISO8601DateFormatter().date(from: dateStr) { return date }
            
            // Try exhaustive list of PostgREST/Supabase formats
            let pFormatter = DateFormatter()
            pFormatter.locale = Locale(identifier: "en_US_POSIX")
            pFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd HH:mm:ssZZZZZ",
                "yyyy-MM-dd HH:mm:ss+ZZ",
                "yyyy-MM-dd HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd"
            ]
            
            for format in formats {
                pFormatter.dateFormat = format
                if let date = pFormatter.date(from: dateStr) { return date }
            }
            
            // If all else fails, try standard ISO8601 as a last resort
            if let date = ISO8601DateFormatter().date(from: dateStr) { return date }
            
            // Throw an error instead of defaulting to Date() so we can identify the format
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(dateStr)")
        }
        return decoder
    }
}
