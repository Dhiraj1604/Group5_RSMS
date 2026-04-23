//
//  CustomerShipmentService.swift
//  Group5_RSMS
//

import Foundation
import Supabase

class CustomerShipmentService {
    private let client = SupabaseManager.shared.client
    
    /// Fetches customer orders. For Pending, we fetch 'placed' (or you can expand this to exclude 'shipped').
    /// The select parameter joins customer_order_items so we have product details.
    func fetchShipments(for tab: ShipmentTab, storeId: UUID?, fromDate: Date? = nil, toDate: Date? = nil) async throws -> [CustomerOrder] {
            var query = client
                .from("customer_orders")
                .select("*, customer_order_items(*, products(*))")
                
            // Use exact PostgREST syntax to bypass Swift array serialization bugs
            if tab == .pending {
                query = query.eq("status", value: "placed")
            } else {
                // This safely fetches BOTH shipped and delivered orders
                query = query.or("status.eq.shipped,status.eq.delivered")
            }
                
            if let storeId = storeId {
                query = query.eq("store_id", value: storeId)
            }
                
            if let from = fromDate {
                query = query.gte("created_at", value: from.ISO8601Format())
            }
            if let to = toDate {
                query = query.lte("created_at", value: to.ISO8601Format())
            }
                
            let response: [CustomerOrder] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value
                
            return response
        }
        
        func updateOrderStatus(orderId: UUID, newStatus: String) async throws {
            struct UpdateStatus: Encodable {
                let status: String
                let updated_at: String
            }
            
            let payload = UpdateStatus(status: newStatus, updated_at: Date().ISO8601Format())
            
            try await client
                .from("customer_orders")
                .update(payload)
                .eq("id", value: orderId)
                .execute()
        }
}
