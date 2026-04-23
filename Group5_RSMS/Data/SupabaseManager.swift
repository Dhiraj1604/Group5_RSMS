//
//  SupabaseManager.swift
//  Group5_RSMS
//
//  Created by Antigravity on 4/15/26.
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

#if !canImport(Supabase)
/// Stub fallback so the app can compile without the Supabase package.
/// Install the Supabase Swift package to enable real functionality:
/// File > Add Packages... > https://github.com/supabase-community/supabase-swift
public struct SupabaseClient {
    public init(supabaseURL: URL, supabaseKey: String) {
        preconditionFailure("Supabase package not installed. Add https://github.com/supabase-community/supabase-swift to your project, then remove the fallback.")
    }
}
#endif

/// Singleton manager for Supabase client access.
/// Requires the `Supabase` Swift Package to be installed.
public final class SupabaseManager {
    public static let shared = SupabaseManager()

    // TODO: ⚠️ REPLACE THESE PLACEHOLDERS WITH YOUR ACTUAL SUPABASE CREDENTIALS ⚠️
    // You can find these in your Supabase project settings under API > Project URL / anon key
    private let supabaseURL = URL(string: "https://bdgwzkpteyxhlgprlmye.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkZ3d6a3B0ZXl4aGxncHJsbXllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTM5OTksImV4cCI6MjA5MTcyOTk5OX0.AU2fdMOK0WfjqQEFqLsMfGCWChf3rMzSdVOzQ_5QYOU"

    public let client: SupabaseClient

    private init() {
        #if canImport(Supabase)
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
        #else
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        #endif
    }
    
    // MARK: - Edge Functions
    
    public func provisionAccount(email: String, storeId: UUID, role: String) async throws {
        #if canImport(Supabase)
        let body: [String: AnyJSON] = [
            "email": .string(email),
            "store_id": .string(storeId.uuidString),
            "role": .string(role)
        ]
        
        try await client.functions.invoke("verify-manager-otp-admin", options: FunctionInvokeOptions(body: body))
        #endif
    }
    
    public func inviteManager(email: String, boutiqueId: UUID) async throws {
        #if canImport(Supabase)
        let body: [String: AnyJSON] = [
            "email": .string(email),
            "boutique_id": .string(boutiqueId.uuidString)
        ]
        
        try await client.functions.invoke("invite-manager", options: FunctionInvokeOptions(body: body))
        #endif
    }
    
    // MARK: - Manager OTP Authentication Flow
    
    public func sendOTP(email: String) async throws {
        #if canImport(Supabase)
        try await client.auth.signInWithOTP(email: email)
        #endif
    }
    
    public func verifyLoginOTP(email: String, otp: String) async throws -> Session? {
        #if canImport(Supabase)
        let response = try await client.auth.verifyOTP(
            email: email,
            token: otp,
            type: .email
        )
        return response.session
        #else
        return nil
        #endif
    }
    
    public func verifyManagerOTPAdmin(email: String, otp: String, storeId: UUID) async throws {
        #if canImport(Supabase)
        let body: [String: AnyJSON] = [
            "email": .string(email),
            "otp": .string(otp),
            "store_id": .string(storeId.uuidString)
        ]
        try await client.functions.invoke("verify-manager-otp-admin", options: FunctionInvokeOptions(body: body))
        #endif
    }
    
    public func updateUserPassword(password: String) async throws {
        #if canImport(Supabase)
        let attributes = UserAttributes(password: password)
        _ = try await client.auth.update(user: attributes)
        #endif
    }
    
    public func inviteInventoryUser(email: String, boutiqueId: UUID) async throws {
        #if canImport(Supabase)
        let _ = try await client.auth.session
        let body: [String: AnyJSON] = [
            "email": .string(email),
            "boutique_id": .string(boutiqueId.uuidString)
        ]
        
        try await client.functions.invoke("invite-inventory", options: FunctionInvokeOptions(body: body))
        #endif
    }

    public func checkEmailRoleExists(email: String) async throws -> Bool {
        #if canImport(Supabase)
        struct ProfileCheck: Codable {
            let role: String
        }
        // Query profiles table to check if this email exists with any role
        let response: [ProfileCheck] = try await client
            .from("profiles")
            .select("role")
            .eq("email", value: email)
            .execute()
            .value
        
        return !response.isEmpty
        #else
        return false
        #endif
    }
}
