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
            }
            
            let payload = UpdateStatus(status: newStatus)
            
            try await client
                .from("customer_orders")
                .update(payload)
                .eq("id", value: orderId)
                .execute()
        }
        
        func getStoreManager(storeId: UUID) async throws -> UUID? {
            struct StoreResult: Decodable {
                let assigned_manager_id: UUID?
            }
            
            let result: [StoreResult] = try await client
                .from("stores")
                .select("assigned_manager_id")
                .eq("id", value: storeId)
                .execute()
                .value
                
            return result.first?.assigned_manager_id
        }
        
        func createTransferTask(storeId: UUID, managerId: UUID?, orderNumber: String) async throws {
            var employeeId: UUID? = nil
            if managerId != nil {
                struct EmployeeResult: Decodable { let id: UUID }
                do {
                    let emps: [EmployeeResult] = try await client
                        .from("employees")
                        .select("id")
                        .eq("boutique_id", value: storeId)
                        .ilike("role", pattern: "%manager%")
                        .execute()
                        .value
                    employeeId = emps.first?.id
                } catch {
                    print("Could not find manager employee: \(error)")
                }
            }
            
            struct NewTask: Encodable {
                let boutique_id: UUID
                let title: String
                let description: String
                let assigned_to: UUID?
                let status: String
            }
            
            let task = NewTask(
                boutique_id: storeId,
                title: "Low Stock for Order #\(orderNumber.prefix(8).uppercased())",
                description: "Order #\(orderNumber.prefix(8).uppercased()) has insufficient stock to ship. Please initiate a transfer.",
                assigned_to: employeeId,
                status: "pending"
            )
            
            try await client
                .from("store_tasks")
                .insert(task)
                .execute()
        }
}
