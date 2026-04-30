import SwiftUI

// MARK: - CorporateAdminTabView
// Root tab container for the Corporate Admin role.

struct CorporateAdminTabView: View {

    @State private var selectedTab: AdminTab = .products

    enum AdminTab {
        case products, offers
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            NavigationView {
//                ProductListView()
            }
            .tabItem {
                Label("Products", systemImage: "square.grid.2x2")
            }
            .tag(AdminTab.products)

            NavigationView {
                OffersView()
            }
            .tabItem {
                Label("Offers", systemImage: "tag")
            }
            .tag(AdminTab.offers)
        }
        // Use the new theme color here!
        .tint(RSMSTheme.Colors.accentGold)
        .colorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    CorporateAdminTabView()
}
