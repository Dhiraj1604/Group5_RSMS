import SwiftUI
import AuthenticationServices

struct TestWebAuth: View {
    @Environment(\.webAuthenticationSession) private var webAuthSession
    var body: some View {
        Button("Test") {
            Task {
                do {
                    let url = URL(string: "https://example.com")!
                    let result = try await webAuthSession.authenticate(
                        using: url,
                        callbackURLScheme: "rsms-app"
                    )
                    print(result)
                } catch {
                    print(error)
                }
            }
        }
    }
}
