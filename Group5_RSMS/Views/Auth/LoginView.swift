//
//  LoginView.swift
//  Group5_RSMS
//
//  Email login screen with luxury dark theme.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isAnimating = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            backgroundOrbs

            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xxl) {
                    Spacer().frame(height: 60)
                    brandHeader
                    loginForm
                    signInButton
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

    // MARK: - Background
    private var backgroundOrbs: some View {
        ZStack {
            Circle()
                .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: isAnimating ? 30 : -30, y: isAnimating ? -50 : 50)

            Circle()
                .fill(RSMSTheme.Colors.accentGoldDark.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: isAnimating ? -40 : 40, y: isAnimating ? 60 : -40)
        }
    }

    // MARK: - Brand Header
    private var brandHeader: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            Text("RSMS")
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            Text("Retail Store Management System")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    // MARK: - Form
    private var loginForm: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            // Email Field
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("Email")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .frame(width: 20)

                    TextField("", text: $email, prompt: Text("Enter your email").foregroundStyle(RSMSTheme.Colors.textTertiary))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }
                .padding(RSMSTheme.Spacing.lg)
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .stroke(RSMSTheme.Colors.border, lineWidth: 1)
                )
            }

            // Password Field
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("Password")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .frame(width: 20)

                    SecureField("", text: $password, prompt: Text("Enter your password").foregroundStyle(RSMSTheme.Colors.textTertiary))
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

    // MARK: - Button
    private var signInButton: some View {
        Button { attemptLogin() } label: {
            Text("Sign In")
        }
        .buttonStyle(GoldButtonStyle())
    }

    // MARK: - Actions
    private func attemptLogin() {
        withAnimation(.easeInOut(duration: 0.3)) { showError = false }

        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { showError = true; errorMessage = "Please enter your email address." }
            return
        }
        guard email.contains("@") && email.contains(".") else {
            withAnimation { showError = true; errorMessage = "Please enter a valid email address." }
            return
        }
        guard !password.isEmpty else {
            withAnimation { showError = true; errorMessage = "Please enter your password." }
            return
        }
        appState.login(email: email)
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
