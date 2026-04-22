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
    func fetchShipments(status: String) async throws -> [CustomerOrder] {
        let response: [CustomerOrder] = try await client
            .from("customer_orders")
            .select("*, customer_order_items(*, products(*))")
            .eq("status", value: status)
            .order("created_at", ascending: false)
            .execute()
            .value
            
        return response
    }
    
    /// Updates the status of an order
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
