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
    private let supabaseKey = "sb_publishable_XHW4yCuvyFHIyuafr8Bm0g_3FhD3jBc"

    public let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
}
