import SwiftUI

struct RSMSProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage("rsms.appearanceMode") private var appearanceModeRaw = RSMSAppearanceMode.dark.rawValue
    @AppStorage("rsms.language") private var appLanguage = "en"

    private var currentStore: Store? {
        guard let id = appState.currentStoreID else { return nil }
        return appState.stores.first(where: { $0.id == id })
    }

    private var displayName: String {
        let email = appState.userEmail
        guard !email.isEmpty else { return "User" }
        let local = email.components(separatedBy: "@").first ?? email
        return local
            .components(separatedBy: CharacterSet(charactersIn: "._-"))
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    private var roleName: LocalizedStringKey {
        switch appState.selectedRole {
        case .boutiqueManager: return "Boutique Manager"
        case .corporateAdmin: return "Corporate Admin"
        case .inventoryController: return "Inventory Controller"
        case .none: return "Guest"
        }
    }
    
    private var accessLevel: LocalizedStringKey {
        switch appState.selectedRole {
        case .boutiqueManager: return "Store Operations"
        case .corporateAdmin: return "Full System Access"
        case .inventoryController: return "Stock Management"
        case .none: return "Limited"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle().fill(RSMSTheme.Colors.accentGold.opacity(0.15)).frame(width: 90, height: 90)
                                Text(String(displayName.prefix(1))).font(.system(size: 38, weight: .bold)).foregroundStyle(RSMSTheme.Colors.goldGradient)
                            }
                            VStack(spacing: 4) {
                                Text(displayName).font(.system(size: 24, weight: .bold)).foregroundColor(RSMSTheme.Colors.textPrimary)
                                Text(appState.userEmail).font(.system(size: 14)).foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 24).background(RSMSTheme.Colors.backgroundElevated).clipShape(RoundedRectangle(cornerRadius: 18))

                        VStack(alignment: .leading, spacing: 0) {
                            sectionLabel("ACCESSIBILITY & APPEARANCE")
                            VStack(alignment: .leading, spacing: 10) {
                                Picker("Appearance", selection: $appearanceModeRaw) {
                                    ForEach(RSMSAppearanceMode.allCases) { mode in Text(mode.title).tag(mode.rawValue) }
                                }.pickerStyle(.segmented)
                            }.padding(16)
                            Divider().padding(.leading, 52)
                            VStack(alignment: .leading, spacing: 10) {
                                Picker("Language", selection: $appLanguage) {
                                    Text("System").tag("system")
                                    Text("English").tag("en")
                                    Text("Español").tag("es")
                                    Text("Français").tag("fr")
                                    Text("Deutsch").tag("de")
                                    Text("Português").tag("pt")
                                    Text("हिंदी").tag("hi")
                                    Text("मराठी").tag("mr")
                                    Text("中文").tag("zh-Hans")
                                    Text("日本語").tag("ja")
                                    Text("العربية").tag("ar")
                                }.pickerStyle(.menu)
                            }.padding(16)
                        }.background(RSMSTheme.Colors.backgroundElevated).clipShape(RoundedRectangle(cornerRadius: 18))

                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { appState.signOut() }
                        } label: {
                            Text("Sign Out").fontWeight(.semibold).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 54).background(RSMSTheme.Colors.error).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("My Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundColor(RSMSTheme.Colors.accentGold) } }
        }
    }
    private func sectionLabel(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).foregroundColor(RSMSTheme.Colors.textSecondary).padding(.horizontal, 16).padding(.top, 14)
    }
}
