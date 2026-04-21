//
//  LowStockService.swift
//  Group5_RSMS
//
//  Supabase service for low-stock alert queries and inter-store transfers.
//  All methods are async and throw on failure.
//

import Foundation
import Supabase

final class LowStockService {

    static let shared = LowStockService()
    private let client = SupabaseManager.shared.client

    private init() {}

    // MARK: - Fetch Low Stock Alerts (All Stores)

    /// Returns all inventory rows where `stock_quantity < threshold`,
    /// joined with product and store details. Used by Inventory Controller.
    func fetchAllLowStockAlerts() async throws -> [LowStockAlert] {
        let alerts: [LowStockAlert] = try await client
            .from("inventory")
            .select("product_id, store_id, stock_quantity, products(*), stores(*)")
            .lt("stock_quantity", value: kLowStockThreshold)
            .order("stock_quantity", ascending: true)
            .execute()
            .value
        return alerts
    }

    // MARK: - Fetch Low Stock Alerts (Single Store)

    /// Returns low-stock items filtered to a specific store.
    /// Used by Boutique Manager.
    func fetchLowStockAlerts(forStore storeId: UUID) async throws -> [LowStockAlert] {
        let alerts: [LowStockAlert] = try await client
            .from("inventory")
            .select("product_id, store_id, stock_quantity, products(*), stores(*)")
            .eq("store_id", value: storeId)
            .lt("stock_quantity", value: kLowStockThreshold)
            .order("stock_quantity", ascending: true)
            .execute()
            .value
        return alerts
    }

    // MARK: - Fetch High-Stock Sources for Transfer

    /// Returns stores that have `stock_quantity > highStockThreshold`
    /// for a given product, excluding the requesting store.
    func fetchHighStockStores(
        forProduct productId: UUID,
        excluding currentStoreId: UUID
    ) async throws -> [TransferSource] {
        let sources: [TransferSource] = try await client
            .from("inventory")
            .select("store_id, stock_quantity, stores(*)")
            .eq("product_id", value: productId)
            .neq("store_id", value: currentStoreId)
            .gt("stock_quantity", value: kHighStockThreshold)
            .order("stock_quantity", ascending: false)
            .execute()
            .value
        return sources
    }

    // MARK: - Transfer Requests (Pull Workflow)
    
    /// Creates a new transfer request from one store to another.
    func createTransferRequest(
        productId: UUID,
        requestingStoreId: UUID,
        fulfillingStoreId: UUID,
        quantity: Int
    ) async throws {
        struct RequestPayload: Encodable {
            let requesting_store_id: UUID
            let fulfilling_store_id: UUID
            let product_id: UUID
            let quantity: Int
            let status: String
        }
        
        let payload = RequestPayload(
            requesting_store_id: requestingStoreId,
            fulfilling_store_id: fulfillingStoreId,
            product_id: productId,
            quantity: quantity,
            status: "pending"
        )
        
        try await client
            .from("transfer_requests")
            .insert(payload)
            .execute()
    }
    
    /// Fetches all pending incoming requests where currentStore is the fulfillingStore.
    func fetchIncomingRequests(forStore storeId: UUID) async throws -> [TransferRequest] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Setup decoding with custom date strategy for PostgREST
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = formatter.date(from: dateStr) { return date }
            if let date = ISO8601DateFormatter().date(from: dateStr) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        let requests: [TransferRequest] = try await client
            .from("transfer_requests")
            .select("*, products(*), requesting_store:requesting_store_id(*), fulfilling_store:fulfilling_store_id(*)")
            .eq("fulfilling_store_id", value: storeId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
            
        return requests
    }
    
    /// Fetches all requests initiated by the currentStore (Outbound/My Requests).
    func fetchMyRequests(forStore storeId: UUID) async throws -> [TransferRequest] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = formatter.date(from: dateStr) { return date }
            if let date = ISO8601DateFormatter().date(from: dateStr) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }
        
        let requests: [TransferRequest] = try await client
            .from("transfer_requests")
            .select("*, products(*), requesting_store:requesting_store_id(*), fulfilling_store:fulfilling_store_id(*)")
            .eq("requesting_store_id", value: storeId)
            .order("created_at", ascending: false)
            .execute()
            .value
            
        return requests
    }
    
    /// Fetches the current stock quantity for an item at a specific store.
    func fetchCurrentStock(productId: UUID, storeId: UUID) async throws -> Int {
        struct InventoryRow: Decodable { let stock_quantity: Int }
        
        let record: [InventoryRow] = try await client
            .from("inventory")
            .select("stock_quantity")
            .eq("product_id", value: productId)
            .eq("store_id", value: storeId)
            .execute()
            .value
            
        return record.first?.stock_quantity ?? 0
    }

    // MARK: - Execute Inter-Store Transfer

    /// Simulates a stock transfer:
    /// 1. Decrements source store quantity
    /// 2. Increments destination store quantity
    /// 3. Logs an audit record
    ///
    /// - Parameters:
    ///   - productId: The product being transferred.
    ///   - fromStoreId: Source store (high stock).
    ///   - toStoreId: Destination store (low stock / requesting store).
    ///   - quantity: Number of units to transfer.
    ///   - productName: Display name for audit log.
    ///   - fromStoreName: Source store name for audit log.
    ///   - toStoreName: Destination store name for audit log.
    ///   - requestId: Optional ID of the transfer request to mark as fulfilled.
    func executeTransfer(
        productId: UUID,
        fromStoreId: UUID,
        toStoreId: UUID,
        quantity: Int,
        productName: String,
        fromStoreName: String,
        toStoreName: String,
        requestId: UUID? = nil
    ) async throws {

        // 1. Read current stock at source
        struct StockRecord: Decodable {
            let stock_quantity: Int
        }

        let sourceRecord: StockRecord = try await client
            .from("inventory")
            .select("stock_quantity")
            .eq("product_id", value: productId)
            .eq("store_id", value: fromStoreId)
            .single()
            .execute()
            .value

        let destRecord: StockRecord = try await client
            .from("inventory")
            .select("stock_quantity")
            .eq("product_id", value: productId)
            .eq("store_id", value: toStoreId)
            .single()
            .execute()
            .value

        guard sourceRecord.stock_quantity >= quantity else {
            throw TransferError.insufficientStock
        }

        // 2. Decrement source
        try await client
            .from("inventory")
            .update(["stock_quantity": sourceRecord.stock_quantity - quantity])
            .eq("product_id", value: productId)
            .eq("store_id", value: fromStoreId)
            .execute()

        // 3. Increment destination
        try await client
            .from("inventory")
            .update(["stock_quantity": destRecord.stock_quantity + quantity])
            .eq("product_id", value: productId)
            .eq("store_id", value: toStoreId)
            .execute()
            
        // 3.5 Mark request as fulfilled if applicable
        if let reqId = requestId {
            try await client
                .from("transfer_requests")
                .update(["status": "fulfilled"])
                .eq("id", value: reqId)
                .execute()
        }

        // 4. Audit log
        struct AuditPayload: Encodable {
            let action: String
            let event_type: String
            let user_name: String
            let entity: String
            let before_data: [String: String]?
            let after_data: [String: String]?
        }

        let audit = AuditPayload(
            action: "INTER_STORE_TRANSFER",
            event_type: "inventory_transfer",
            user_name: "Boutique Manager",
            entity: "Inventory",
            before_data: [
                "product": productName,
                "from_store": fromStoreName,
                "source_stock_before": "\(sourceRecord.stock_quantity)",
                "dest_stock_before": "\(destRecord.stock_quantity)"
            ],
            after_data: [
                "product": productName,
                "to_store": toStoreName,
                "quantity_transferred": "\(quantity)",
                "source_stock_after": "\(sourceRecord.stock_quantity - quantity)",
                "dest_stock_after": "\(destRecord.stock_quantity + quantity)"
            ]
        )

        try await client
            .from("audit_logs")
            .insert(audit)
            .execute()

        print("✅ Transfer complete: \(quantity)× \(productName) from \(fromStoreName) → \(toStoreName)")
    }
}

// MARK: - Errors

enum TransferError: LocalizedError {
    case insufficientStock

    var errorDescription: String? {
        switch self {
        case .insufficientStock:
            return "Source store does not have enough stock for this transfer."
        }
    }
}
