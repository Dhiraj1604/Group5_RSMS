import Foundation
import Supabase

func testSignIn() async throws {
    let client = SupabaseClient(supabaseURL: URL(string: "https://test.com")!, supabaseKey: "key")
    _ = try await client.auth.signIn(email: "a@b.com", password: "pwd")
    _ = try await client.auth.signUp(email: "a@b.com", password: "pwd")
}
