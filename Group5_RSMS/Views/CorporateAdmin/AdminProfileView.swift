//
//  AdminProfileView.swift
//  Group5_RSMS
//
//  Corporate Admin — Profile modal with Accessibility features.
//

import SwiftUI

struct AdminProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @AppStorage("rsms.appearanceMode") private var appearanceModeRaw = RSMSAppearanceMode.dark.rawValue

    /// Derive a readable name from the email local part (e.g. "admin.user@…" → "Admin User")
    private var displayName: String {
        let email = appState.userEmail
        guard !email.isEmpty else { return "Corporate Admin" }
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

                        // ── Avatar + Name + Email ───────────────────────
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
                                Text("Admin Session")
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

                        // ── Appearance & Accessibility ──────────────────
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

                        // ── Role ────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 0) {
                            sectionLabel("ROLE & ACCESS")
                            ProfileInfoRow(icon: "person.badge.key.fill", iconColor: RSMSTheme.Colors.accentGold,
                                           title: "Role", value: "Corporate Admin")
                            rowDivider
                            ProfileInfoRow(icon: "shield.fill",           iconColor: RSMSTheme.Colors.success,
                                           title: "Access Level", value: "Global Management")
                        }
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))


                        // ── Sign Out ────────────────────────────────────
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
            .navigationTitle("Admin Profile")
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

#Preview {
    AdminProfileView().environment(AppState())
}
