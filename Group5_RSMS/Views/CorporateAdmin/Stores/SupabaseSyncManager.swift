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
}
