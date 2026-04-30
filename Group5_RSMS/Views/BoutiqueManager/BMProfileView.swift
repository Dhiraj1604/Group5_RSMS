//
//  BMProfileView.swift
//  Group5_RSMS
//
//  Boutique Manager — Profile modal. Uses shared RSMSTheme.
//

import SwiftUI

struct BMProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage("rsms.appearanceMode") private var appearanceModeRaw = RSMSAppearanceMode.dark.rawValue

    private var currentStore: Store? {
        guard let id = appState.currentStoreID else { return nil }
        return appState.stores.first(where: { $0.id == id })
    }

    /// Derive a readable name from the email local part (e.g. "john.doe@…" → "John Doe")
    private var displayName: String {
        let email = appState.userEmail
        guard !email.isEmpty else { return "Boutique Manager" }
        let local = email.components(separatedBy: "@").first ?? email
        return local
            .components(separatedBy: CharacterSet(charactersIn: "._-"))
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Avatar + Name + Email
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                Text(String(displayName.prefix(1)))
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
                            }
                            VStack(spacing: 4) {
                                Text(displayName)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                                Text(appState.userEmail)
                                    .font(.system(size: 14))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                            // Active session badge
                            HStack(spacing: 6) {
                                Circle().fill(RSMSTheme.Colors.success).frame(width: 7, height: 7)
                                Text("Active Session")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(RSMSTheme.Colors.success)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(RSMSTheme.Colors.success.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))

                        // Store Details
                        if let store = currentStore {
                            VStack(alignment: .leading, spacing: 0) {
                                sectionLabel("MY STORE")
                                ProfileInfoRow(icon: "storefront.fill",         iconColor: RSMSTheme.Colors.accentGold,
                                               title: "Store Name", value: store.name)
                                rowDivider
                                ProfileInfoRow(icon: "mappin.circle.fill",      iconColor: RSMSTheme.Colors.error,
                                               title: "City", value: store.city)
                                rowDivider
                                ProfileInfoRow(icon: "globe.asia.australia.fill", iconColor: RSMSTheme.Colors.warning,
                                               title: "Country", value: store.country)
                                if let phone = store.phone, !phone.isEmpty {
                                    rowDivider
                                    ProfileInfoRow(icon: "phone.fill",          iconColor: RSMSTheme.Colors.success,
                                                   title: "Store Phone", value: phone)
                                }
                            }
                            .background(RSMSTheme.Colors.backgroundElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                        }

                        // Appearance & Contrast
                        VStack(alignment: .leading, spacing: 0) {
                            sectionLabel("ACCESSIBILITY & APPEARANCE")
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(RSMSTheme.Colors.accentGold.opacity(0.14))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "circle.lefthalf.filled")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(RSMSTheme.Colors.accentGold)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Appearance")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                        Text("Choose light, dark, or follow device settings.")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    }
                                    Spacer()
                                }

                                Picker("Appearance", selection: $appearanceModeRaw) {
                                    ForEach(RSMSAppearanceMode.allCases) { mode in
                                        Text(mode.title).tag(mode.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityLabel("Appearance")
                                .accessibilityValue(selectedAppearanceTitle)
                                .accessibilityHint("Choose whether the app uses system appearance, light mode, or dark mode.")

                                Text("High contrast follows the iOS accessibility contrast setting.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                        }
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))

                        // Role
                        VStack(alignment: .leading, spacing: 0) {
                            sectionLabel("ROLE & ACCESS")
                            ProfileInfoRow(icon: "person.badge.key.fill", iconColor: RSMSTheme.Colors.accentGold,
                                           title: "Role", value: "Boutique Manager")
                            rowDivider
                            ProfileInfoRow(icon: "building.2.fill",       iconColor: RSMSTheme.Colors.accentGoldLight,
                                           title: "Access Level", value: "Store Operations")
                        }
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))

                        // Sign Out
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                appState.signOut()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Sign Out")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(RSMSTheme.Colors.error)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.top, 8)
                        .accessibilityLabel("Sign out")
                        .accessibilityHint("Signs you out of the current account.")
                    }
                    .padding(20)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .accessibilityLabel("Close profile")
                }
            }
        }
    }

    private var selectedAppearanceTitle: String {
        (RSMSAppearanceMode(rawValue: appearanceModeRaw) ?? .dark).title
    }

    private var rowDivider: some View {
        Divider()
            .background(RSMSTheme.Colors.borderLight)
            .padding(.leading, 52)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.6)
            .foregroundColor(RSMSTheme.Colors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

#Preview {
    BMProfileView().environment(AppState())
}
