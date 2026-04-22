//
//  OTPVerificationView.swift
//  Group5_RSMS
//

import SwiftUI

struct OTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let managerEmail: String
    let storeId: UUID
    let onVerified: () -> Void
    
    @State private var otp = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAnimating = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                backgroundOrbs

                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xxl) {
                        Spacer().frame(height: 40)
                        header
                        otpForm
                        verifyButton
                        Spacer()
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.xl)
                }
            }
            .navigationTitle("Manager Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
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

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }

            Text("Verify Manager")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            Text("Enter the 6-digit OTP sent to \(managerEmail).\nThe manager must provide this verbally.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var otpForm: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                Text("Verification Code")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)

                HStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "number")
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .frame(width: 20)

                    TextField("", text: $otp, prompt: Text("XXXXXX").foregroundStyle(RSMSTheme.Colors.textTertiary))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .keyboardType(.numberPad)
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

    private var verifyButton: some View {
        Button { performVerification() } label: {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Verify & Continue")
            }
        }
        .buttonStyle(GoldButtonStyle())
        .disabled(isLoading)
    }

    private func performVerification() {
        withAnimation(.easeInOut(duration: 0.3)) { showError = false }

        guard !otp.isEmpty else {
            withAnimation { showError = true; errorMessage = "Please enter the OTP." }
            return
        }

        isLoading = true
        
        Task {
            do {
                try await SupabaseManager.shared.verifyManagerOTPAdmin(
                    email: managerEmail,
                    otp: otp,
                    storeId: storeId
                )
                
                await MainActor.run {
                    onVerified()
                    dismiss()
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
    OTPVerificationView(managerEmail: "manager@example.com", storeId: UUID()) {
        print("Verified")
    }
}
