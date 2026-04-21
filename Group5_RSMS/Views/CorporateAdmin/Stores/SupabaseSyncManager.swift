//
//  SupabaseSyncManager.swift
//  Group5_RSMS
//

import Foundation
import Supabase

@MainActor
final class SupabaseSyncManager {

    static let shared = SupabaseSyncManager()
    private init() {}

    // MARK: - Decoder
    private var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(str)"
            )
        }
        return decoder
    }

    // MARK: - Client
    private let client: SupabaseClient = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(str)"
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        return SupabaseClient(
            supabaseURL: URL(string: "https://bdgwzkpteyxhlgprlmye.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkZ3d6a3B0ZXl4aGxncHJsbXllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTM5OTksImV4cCI6MjA5MTcyOTk5OX0.AU2fdMOK0WfjqQEFqLsMfGCWChf3rMzSdVOzQ_5QYOU",
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: encoder,
                    decoder: decoder
                )
            )
        )
    }()

    private let table = "stores"

    // MARK: - CREATE
    func createStore(_ store: Store) async throws {
        try await client.from(table).insert(store).execute()
    }

    // MARK: - READ ALL
    func fetchStores() async throws -> [Store] {
        let response = try await client
            .from(table)
            .select()
            .execute()

        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("RAW JSON: \(jsonString)")
        }

        let stores = try supabaseDecoder.decode([Store].self, from: response.data)
        print("Fetched \(stores.count) stores successfully")
        return stores
    }

    // MARK: - READ BY ID
    func fetchStore(by id: UUID) async throws -> Store? {
        let response = try await client
            .from(table)
            .select()
            .eq("id", value: id.uuidString)
            .execute()

        let results = try supabaseDecoder.decode([Store].self, from: response.data)
        return results.first
    }

    // MARK: - UPDATE
    func updateStore(_ store: Store) async throws {
        try await client
            .from(table)
            .update(store)
            .eq("id", value: store.id.uuidString)
            .execute()
    }

    // MARK: - DELETE
    func deleteStore(id: UUID) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // Boutique Manager(Staff tab)
    
    // MARK: - Employees
    func fetchEmployees(boutiqueId: UUID) async throws -> [Employee] {
        let response = try await client
            .from("employees")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString)
            .eq("is_active", value: true)
            .execute()
        return try supabaseDecoder.decode([Employee].self, from: response.data)
    }

    func createEmployee(_ employee: Employee) async throws {
        try await client.from("employees").insert(employee).execute()
    }

    func updateEmployee(_ employee: Employee) async throws {
        try await client
            .from("employees")
            .update(employee)
            .eq("id", value: employee.id.uuidString)
            .execute()
    }

    func deactivateEmployee(id: UUID) async throws {
        try await client
            .from("employees")
            .update(["is_active": false])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Commission Rates
    func fetchCommissionRates(boutiqueId: UUID) async throws -> [CommissionRate] {
        let response = try await client
            .from("commission_rates")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString)
            .execute()
        return try supabaseDecoder.decode([CommissionRate].self, from: response.data)
    }

    func setCommissionRate(_ rate: CommissionRate) async throws {
        try await client.from("commission_rates").insert(rate).execute()
    }

    func updateCommissionRate(_ rate: CommissionRate) async throws {
        try await client
            .from("commission_rates")
            .update(rate)
            .eq("id", value: rate.id.uuidString)
            .execute()
    }

    // MARK: - Commission Payouts
    func fetchPayouts(for employeeId: UUID) async throws -> [CommissionPayout] {
        let response = try await client
            .from("commission_payouts")
            .select()
            .eq("employee_id", value: employeeId.uuidString)
            .execute()
        return try supabaseDecoder.decode([CommissionPayout].self, from: response.data)
    }

    func createPayout(_ payout: CommissionPayout) async throws {
        try await client.from("commission_payouts").insert(payout).execute()
    }

    func approvePayout(id: UUID, approvedBy: UUID) async throws {
        try await client
            .from("commission_payouts")
            .update([
                "status": "approved",
                "approved_by": approvedBy.uuidString,
                "approved_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Employee Sales Summary
    func fetchSalesPerEmployee(boutiqueId: UUID) async throws -> [EmployeeSalesSummary] {
//        let response = try await client
//            .from("customer_orders")
//            .select("employee_id, total_amount")
//            .eq("boutique_id", value: boutiqueId.uuidString)
//            .execute()
//
//        // Decode raw orders and manually sum per employee
//        struct RawOrder: Codable {
//            let employeeId: UUID
//            let totalAmount: Double
//
//            enum CodingKeys: String, CodingKey {
//                case employeeId  = "employee_id"
//                case totalAmount = "total_amount"
//            }
//        }
//
//        let orders = try supabaseDecoder.decode([RawOrder].self, from: response.data)
//
//        // Group and sum by employeeId
//        var salesMap: [UUID: Double] = [:]
//        for order in orders {
//            salesMap[order.employeeId, default: 0.0] += order.totalAmount
//        }
//
//        return salesMap.map { EmployeeSalesSummary(employeeId: $0.key, totalSales: $0.value) }
        return []
    }

    // MARK: - Store Tasks
    func fetchTasks(boutiqueId: UUID) async throws -> [StoreTask] {
        let response = try await client
            .from("store_tasks")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        return try supabaseDecoder.decode([StoreTask].self, from: response.data)
    }

    func createTask(_ task: StoreTask) async throws {
        try await client.from("store_tasks").insert(task).execute()
    }

    func updateTask(_ task: StoreTask) async throws {
        try await client
            .from("store_tasks")
            .update(task)
            .eq("id", value: task.id.uuidString)
            .execute()
    }

    func deleteTask(id: UUID) async throws {
        try await client
            .from("store_tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
