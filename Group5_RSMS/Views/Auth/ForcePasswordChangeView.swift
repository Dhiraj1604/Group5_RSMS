//
//  ForcePasswordChangeView.swift
//  Group5_RSMS
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct ForcePasswordChangeView: View {
    @Environment(AppState.self) private var appState
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: RSMSTheme.Spacing.xl) {
                Spacer().frame(height: 60)

                VStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    
                    Text("Secure Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)

                    Text("Your administrator has provided a temporary password. Please set a new secure password before proceeding.")
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: RSMSTheme.Spacing.lg) {
                    // New Password Field
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                        Text("New Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .textCase(.uppercase)

                        HStack(spacing: RSMSTheme.Spacing.md) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .frame(width: 20)

                            SecureField("", text: $newPassword, prompt: Text("Enter new password").foregroundStyle(RSMSTheme.Colors.textTertiary))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        }
                        .padding(RSMSTheme.Spacing.lg)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .stroke(RSMSTheme.Colors.border, lineWidth: 1)
                        )
                    }

                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                        Text("Confirm Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .textCase(.uppercase)

                        HStack(spacing: RSMSTheme.Spacing.md) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .frame(width: 20)

                            SecureField("", text: $confirmPassword, prompt: Text("Confirm new password").foregroundStyle(RSMSTheme.Colors.textTertiary))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        }
                        .padding(RSMSTheme.Spacing.lg)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .stroke(RSMSTheme.Colors.border, lineWidth: 1)
                        )
                    }

                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.error)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .padding(RSMSTheme.Spacing.xl)
                .background(RSMSTheme.Colors.backgroundDeep.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                )

                Button {
                    updatePassword()
                } label: {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Update Password & Enter")
                    }
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(isLoading)

                Spacer()
            }
            .padding(.horizontal, RSMSTheme.Spacing.xl)
        }
    }

    private func updatePassword() {
        withAnimation { showError = false }

        guard !newPassword.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Please enter a new password.")
            return
        }
        
        guard newPassword == confirmPassword else {
            showError("Passwords do not match.")
            return
        }
        
        guard newPassword.count >= 6 else {
            showError("Password must be at least 6 characters.")
            return
        }

        isLoading = true

        Task {
            do {
                #if canImport(Supabase)
                // We update the password AND simultaneously clear the requirement metadata tag!
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(
                        password: newPassword,
                        data: ["requires_password_change": .bool(false)]
                    )
                )
                #endif
                
                await MainActor.run {
                    isLoading = false
                    withAnimation(.spring()) {
                        // Unblocks the user from the dashboard!
                        appState.requiresPasswordChange = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ message: String) {
        withAnimation {
            showError = true
            errorMessage = message
        }
    }
}

#Preview {
    ForcePasswordChangeView()
        .environment(AppState())
}
