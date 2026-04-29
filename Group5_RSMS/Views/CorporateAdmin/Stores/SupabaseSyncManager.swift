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
            
            // Full ISO8601 with fractional seconds (3 digits usually)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            
            // Full ISO8601 without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            //             formatter.formatOptions = [.withFullDate] // Handles YYYY-MM-DD
            //             if let date = formatter.date(from: str) { return date }
            
            // Fallbacks for Supabase's high-precision 6-digit microseconds
            let fractionFormatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ]
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            for format in fractionFormatters {
                fallbackFormatter.dateFormat = format
                // In DateFormatter, 'Z' matches things like +0000 or +00:00 depending on locale,
                // but for strict ISO strings like +00:00 it might need 'ZZZZZ'.
                // A better approach for variable ISO strings with fractions is:
                fallbackFormatter.dateFormat = format.replacingOccurrences(of: "Z", with: "ZZZZZ")
                if let date = fallbackFormatter.date(from: str) { return date }
                
                // standard Z
                fallbackFormatter.dateFormat = format
                if let date = fallbackFormatter.date(from: str) { return date }
            }
            
            // Plain date only e.g. "2026-04-21"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = dateFormatter.date(from: str) { return date }
            
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
            //             formatter.formatOptions = [.withFullDate]
            //             if let date = formatter.date(from: str) { return date }
            
            let fractionFormatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ]
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
            fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            for format in fractionFormatters {
                fallbackFormatter.dateFormat = format.replacingOccurrences(of: "Z", with: "ZZZZZ")
                if let date = fallbackFormatter.date(from: str) { return date }
                
                fallbackFormatter.dateFormat = format
                if let date = fallbackFormatter.date(from: str) { return date }
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = dateFormatter.date(from: str) { return date }
            
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
            .execute()
        
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("RAW EMPLOYEES JSON: \(jsonString)")  // ← add this
        }
        
        return try supabaseDecoder.decode([Employee].self, from: response.data)
    }
    
    func createEmployee(_ employee: Employee) async throws {
        try await client
            .from("employees")
            .insert(employee)
            .execute()
    }
    
    func updateEmployee(_ employee: Employee) async throws {
        try await client
            .from("employees")
            .update(employee)
            .eq("id", value: employee.id.uuidString)
            .execute()
    }
    
    func toggleEmployeeStatus(id: UUID, isActive: Bool) async throws {
        try await client
            .from("employees")
            .update(["is_active": isActive])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func deleteEmployee(id: UUID) async throws {
        try await client
            .from("employees")
            .delete()
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
            .eq("id", value: rate.id.uuidString.lowercased())
            .execute()
    }
    
    func deleteCommissionRate(id: UUID) async throws {
        try await client
            .from("commission_rates")
            .delete()
            .eq("id", value: id.uuidString)
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
                "approved_by": approvedBy.uuidString.lowercased(),
                "approved_at": ISO8601DateFormatter().string(from: Date()),
                "payout_date": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: id.uuidString)
            .execute()
    }
    

    // MARK: - Employee Sales Summary (date range — pass nil for all-time)
    func fetchSalesPerEmployee(boutiqueId: UUID, from: Date? = nil, to: Date? = nil) async throws -> [EmployeeSalesSummary] {
        struct RawOrder: Codable {
            let employeeId: UUID?
            let totalAmount: Double
            
            enum CodingKeys: String, CodingKey {
                case employeeId  = "employee_id"
                case totalAmount = "total_amount"
            }
        }
        
        var query = client
            .from("customer_orders")
            .select("employee_id, total_amount")
            .eq("store_id", value: boutiqueId.uuidString)
        
        if let from = from {
            query = query.gte("created_at", value: ISO8601DateFormatter().string(from: from))
        }
        if let to = to {
            query = query.lte("created_at", value: ISO8601DateFormatter().string(from: to))
        }
        
        let response = try await query.execute()
        let orders = try supabaseDecoder.decode([RawOrder].self, from: response.data)
        
        var salesMap: [UUID: (total: Double, count: Int)] = [:]
        for order in orders {
            guard let empId = order.employeeId else { continue }
            let current = salesMap[empId] ?? (0.0, 0)
            salesMap[empId] = (current.total + order.totalAmount, current.count + 1)
        }
        
        return salesMap.map { (empId, stats) in
            EmployeeSalesSummary(employeeId: empId, totalSales: stats.total, orderCount: stats.count)
        }
    }
    
    // MARK: - Staff Shifts
    func fetchShifts(boutiqueId: UUID) async throws -> [Shift] {
        let response = try await client
            .from("shifts")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString)
            .execute()
        return try supabaseDecoder.decode([Shift].self, from: response.data)
    }
    
    func createShift(_ shift: Shift) async throws {
        try await client.from("shifts").insert(shift).execute()
    }
    
    func updateShift(_ shift: Shift) async throws {
        try await client
            .from("shifts")
            .update(shift)
            .eq("id", value: shift.id.uuidString)
            .execute()
    }
    
    func deleteShift(id: UUID) async throws {
        try await client
            .from("shifts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Commission Payout Delete
    func deletePayout(id: UUID) async throws {
        try await client
            .from("commission_payouts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - All Payouts for a Boutique (Dashboard use)
    func fetchAllPayouts(boutiqueId: UUID) async throws -> [CommissionPayout] {
        let response = try await client
            .from("commission_payouts")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString.lowercased())
            .execute()
        return try supabaseDecoder.decode([CommissionPayout].self, from: response.data)
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
    
    func fetchBoutiqueOrders(boutiqueId: UUID) async throws -> [EmployeeOrder] {
        return try await client
            .from("orders")
            .select()
            .eq("boutique_id", value: boutiqueId.uuidString)
            .execute()
            .value
    }
}

