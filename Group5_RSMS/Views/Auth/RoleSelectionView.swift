//
//  RoleSelectionView.swift
//  Group5_RSMS
//
//  Choose between Corporate Admin, Boutique Manager,
//  or Inventory Controller.
//

import SwiftUI

struct RoleSelectionView: View {
    @Environment(AppState.self) private var appState
    @State private var hoveredRole: UserRole? = nil
    @State private var appeared = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xxl) {
                    Spacer().frame(height: 40)
                    header
                    roleCards
                    logoutButton
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, RSMSTheme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            Text("Welcome Back")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)

            Text("Select Your Role")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            Text(appState.userEmail)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.accentGold)
                .padding(.top, RSMSTheme.Spacing.xs)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Cards
    private var roleCards: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ForEach(Array(UserRole.allCases.enumerated()), id: \.element) { index, role in
                roleCard(role: role)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(
                        .easeOut(duration: 0.5).delay(Double(index) * 0.15),
                        value: appeared
                    )
            }
        }
    }

    private func roleCard(role: UserRole) -> some View {
        Button {
            appState.selectRole(role)
        } label: {
            HStack(spacing: RSMSTheme.Spacing.lg) {
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .fill(role.accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: role.icon)
                        .font(.title2)
                        .foregroundStyle(role.accentColor)
                }

                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                    Text(role.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)

                    Text(role.description)
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(
                        hoveredRole == role
                            ? role.accentColor.opacity(0.5)
                            : RSMSTheme.Colors.borderLight,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredRole = isHovered ? role : nil
            }
        }
    }

    // MARK: - Logout
    private var logoutButton: some View {
        Button {
            appState.logout()
        } label: {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Image(systemName: "arrow.left.circle")
                Text("Sign out")
            }
            .font(.subheadline)
            .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .padding(.top, RSMSTheme.Spacing.md)
    }
}

#Preview {
    let state = AppState()
    state.login(email: "admin@rsms.com")
    return RoleSelectionView()
        .environment(state)
}
