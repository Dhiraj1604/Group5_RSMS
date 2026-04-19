//
//  SupabaseConfig.swift
//  Group5_RSMS
//
//  Centralized Supabase configuration.
//  Reads credentials from Environment.plist so they are never hardcoded in service classes.
//

import Foundation

enum SupabaseConfig {

    // MARK: - Public accessors

    /// Base URL for the Supabase project (e.g. "https://xxx.supabase.co")
    static var url: String {
        value(for: "SUPABASE_URL") ?? fallbackURL
    }

    /// Anonymous (public) API key
    static var anonKey: String {
        value(for: "SUPABASE_ANON_KEY") ?? fallbackAnonKey
    }

    // MARK: - Plist reader

    private static func value(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Environment", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let val  = dict[key] as? String,
              !val.isEmpty
        else { return nil }
        return val
    }

    // MARK: - Fallbacks (keep in sync with Environment.plist)

    private static let fallbackURL     = "https://bdgwzkpteyxhlgprlmye.supabase.co"
    private static let fallbackAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkZ3d6a3B0ZXl4aGxncHJsbXllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxNTM5OTksImV4cCI6MjA5MTcyOTk5OX0.AU2fdMOK0WfjqQEFqLsMfGCWChf3rMzSdVOzQ_5QYOU"
}
