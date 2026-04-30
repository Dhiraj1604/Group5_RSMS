//
//  SetPasswordView.swift
//  Group5_RSMS
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct SetPasswordView: View {
    @Environment(AppState.self) private var appState
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isAnimating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            backgroundOrbs

            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xxl) {
                    Spacer().frame(height: 60)
                    header
                    passwordForm
                    submitButton
                    Spacer()
                }
                .padding(.horizontal, RSMSTheme.Spacing.xl)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: isAnimating ? 30 : -30, y: isAnimating ? -50 : 50)
        }
    }

    private var header: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            Text("Set Password")
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            Text("Please secure your manager account.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    private var passwordForm: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("New Password")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "lock.fill")
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

            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("Confirm Password")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "lock.fill")
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
    }

    private var submitButton: some View {
        Button { setPassword() } label: {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Set Password & Proceed")
            }
        }
        .buttonStyle(GoldButtonStyle())
        .disabled(isLoading)
    }

    private func setPassword() {
        withAnimation(.easeInOut(duration: 0.3)) { showError = false }

        guard !newPassword.isEmpty else {
            withAnimation { showError = true; errorMessage = "Please enter a new password." }
            return
        }
        guard newPassword == confirmPassword else {
            withAnimation { showError = true; errorMessage = "Passwords do not match." }
            return
        }
        guard newPassword.count >= 6 else {
            withAnimation { showError = true; errorMessage = "Password must be at least 6 characters." }
            return
        }

        isLoading = true
        
        Task {
            do {
                // Update both password and metadata in Auth, and the flag in Profiles table
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(
                        password: newPassword,
                        data: ["requires_password_change": .bool(false)]
                    )
                )

                if let userId = appState.managerAuthId {
                    struct ProfileUpdate: Encodable {
                        let requires_password_setup: Bool
                    }
                    try await SupabaseManager.shared.client
                        .from("profiles")
                        .update(ProfileUpdate(requires_password_setup: false))
                        .eq("id", value: userId)
                        .execute()
                }
                
                await MainActor.run {
                    appState.requiresPasswordChange = false // Proceeds to main app
                }
            } catch {
                await MainActor.run {
                    withAnimation { 
                        showError = true
                        errorMessage = error.localizedDescription 
                    }
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SetPasswordView()
        .environment(AppState())
}
