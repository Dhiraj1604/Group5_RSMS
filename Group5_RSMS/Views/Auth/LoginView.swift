
//
//  LoginView.swift
//  Group5_RSMS
//
//  Email login screen with luxury dark theme.
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isAnimating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSignUp = false
    @State private var isOTPLogin = false
    @State private var showOTPVerification = false
    @State private var isLoading = false
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

    private var loginForm: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            
            // Login Method Selector
            VStack(spacing: RSMSTheme.Spacing.sm) {
                Picker("Login Method", selection: $isOTPLogin) {
                    Text("Password Login").tag(false)
                    Text("First Time User").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RSMSTheme.Spacing.xs)
                
            }
            .padding(.bottom, RSMSTheme.Spacing.sm)

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

            // Password Field (only show if not OTP login)
            if !isOTPLogin {
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
            }

            if isSignUp {
                // Confirm Password Field
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

                        SecureField("", text: $confirmPassword, prompt: Text("Confirm your password").foregroundStyle(RSMSTheme.Colors.textTertiary))
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
        VStack(spacing: RSMSTheme.Spacing.md) {
            Button { attemptLogin() } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isOTPLogin ? "Send Verification Code" : (isSignUp ? "Sign Up" : "Sign In"))
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(isLoading)
            
            if !isOTPLogin {
                Button {
                    withAnimation {
                        isSignUp.toggle()
                        showError = false
                        errorMessage = ""
                    }
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.footnote)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
        }
        .fullScreenCover(isPresented: $showOTPVerification) {
            ManagerOTPView(email: email)
        }
    }

    // MARK: - Actions
    private func attemptLogin() {
        withAnimation(.easeInOut(duration: 0.3)) { showError = false }

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            withAnimation { showError = true; errorMessage = "Please enter your email address." }
            return
        }
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            withAnimation { showError = true; errorMessage = "Please enter a valid email address." }
            return
        }
        if isOTPLogin {
            isLoading = true
            Task {
                do {
                    // Check if a role is assigned to this email before sending OTP
                    let hasRole = try await SupabaseManager.shared.checkEmailRoleExists(email: trimmedEmail)
                    
                    if !hasRole {
                        await MainActor.run {
                            withAnimation {
                                showError = true
                                errorMessage = "No role found for this email. Please contact your Corporate Admin."
                            }
                            isLoading = false
                        }
                        return
                    }

                    try await SupabaseManager.shared.sendOTP(email: trimmedEmail)
                    await MainActor.run {
                        isLoading = false
                        showOTPVerification = true
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
            return
        }

        guard !password.isEmpty else {
            withAnimation { showError = true; errorMessage = "Please enter your password." }
            return
        }
        
        if isSignUp {
            guard password == confirmPassword else {
                withAnimation { showError = true; errorMessage = "Passwords do not match." }
                return
            }
        }
        
        isLoading = true
        Task {
            do {
                #if canImport(Supabase)
                if isSignUp {
                    _ = try await SupabaseManager.shared.client.auth.signUp(email: trimmedEmail, password: password)
                    try await appState.login(email: trimmedEmail)
                    await MainActor.run { isLoading = false }
                } else {
                    // 1. Verify password via standard sign in
                    _ = try await SupabaseManager.shared.client.auth.signIn(email: trimmedEmail, password: password)
                    
                    // 2. Trigger OTP for 2FA
                    try await SupabaseManager.shared.sendOTP(email: trimmedEmail)
                    
                    // 3. Show OTP view instead of logging in immediately
                    await MainActor.run {
                        isLoading = false
                        showOTPVerification = true
                    }
                }
                #else
                try await appState.login(email: trimmedEmail)
                await MainActor.run { isLoading = false }
                #endif
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
    LoginView()
        .environment(AppState())
}



//  LoginView.swift
//  Group5_RSMS
//
//  Email login screen with luxury dark theme.


//---------------------------

//
//import SwiftUI
////#if canImport(Supabase)
//import Supabase
////#endif
//
//struct LoginView: View {
//    @Environment(AppState.self) private var appState
//    @State private var email = ""
//    @State private var password = ""
//    @State private var confirmPassword = ""
//    @State private var isAnimating = false
//    @State private var showError = false
//    @State private var errorMessage = ""
//    @State private var isSignUp = false
//    @State private var isOTPLogin = false
//    @State private var showOTPVerification = false
//    @State private var isLoading = false
//    var body: some View {
//        ZStack {
//            RSMSTheme.Colors.backgroundPrimary
//                .ignoresSafeArea()
//
//            backgroundOrbs
//
//            ScrollView {
//                VStack(spacing: RSMSTheme.Spacing.xxl) {
//                    Spacer().frame(height: 60)
//                    brandHeader
//                    loginForm
//                    signInButton
//                    Spacer()
//                }
//                .padding(.horizontal, RSMSTheme.Spacing.xl)
//            }
//        }
//        .onAppear {
//            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
//                isAnimating = true
//            }
//        }
//    }
//
//    // MARK: - Background
//    private var backgroundOrbs: some View {
//        ZStack {
//            Circle()
//                .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
//                .frame(width: 300, height: 300)
//                .blur(radius: 80)
//                .offset(x: isAnimating ? 30 : -30, y: isAnimating ? -50 : 50)
//
//            Circle()
//                .fill(RSMSTheme.Colors.accentGoldDark.opacity(0.06))
//                .frame(width: 250, height: 250)
//                .blur(radius: 70)
//                .offset(x: isAnimating ? -40 : 40, y: isAnimating ? 60 : -40)
//        }
//    }
//
//    // MARK: - Brand Header
//    private var brandHeader: some View {
//        VStack(spacing: RSMSTheme.Spacing.md) {
//            ZStack {
//                Circle()
//                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
//                    .frame(width: 80, height: 80)
//
//                Image(systemName: "building.2.crop.circle.fill")
//                    .font(.system(size: 40))
//                    .foregroundStyle(RSMSTheme.Colors.accentGold)
//            }
//
//            Text("RSMS")
//                .font(.system(size: 36, weight: .bold, design: .default))
//                .foregroundStyle(RSMSTheme.Colors.textPrimary)
//
//            Text("Retail Store Management System")
//                .font(.subheadline)
//                .foregroundStyle(RSMSTheme.Colors.textSecondary)
//        }
//    }
//
//    private var loginForm: some View {
//        VStack(spacing: RSMSTheme.Spacing.lg) {
//            
//            // Login Method Selector
//            VStack(spacing: RSMSTheme.Spacing.sm) {
//                Picker("Login Method", selection: $isOTPLogin) {
//                    Text("Password Login").tag(false)
//                    Text("First Time User").tag(true)
//                }
//                .pickerStyle(.segmented)
//                .padding(.horizontal, RSMSTheme.Spacing.xs)
//                
//            }
//            .padding(.bottom, RSMSTheme.Spacing.sm)
//
//            // Email Field
//            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
//                Text("Email")
//                    .font(.caption)
//                    .fontWeight(.semibold)
//                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
//                    .textCase(.uppercase)
//
//                HStack(spacing: RSMSTheme.Spacing.md) {
//                    Image(systemName: "envelope.fill")
//                        .foregroundStyle(RSMSTheme.Colors.accentGold)
//                        .frame(width: 20)
//
//                    TextField("", text: $email, prompt: Text("Enter your email").foregroundStyle(RSMSTheme.Colors.textTertiary))
//                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
//                        .textInputAutocapitalization(.never)
//                        .keyboardType(.emailAddress)
//                        .autocorrectionDisabled()
//                }
//                .padding(RSMSTheme.Spacing.lg)
//                .background(RSMSTheme.Colors.backgroundElevated)
//                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
//                .overlay(
//                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
//                        .stroke(RSMSTheme.Colors.border, lineWidth: 1)
//                )
//            }
//
//            // Password Field (only show if not OTP login)
//            if !isOTPLogin {
//                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
//                    Text("Password")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
//                        .textCase(.uppercase)
//
//                    HStack(spacing: RSMSTheme.Spacing.md) {
//                        Image(systemName: "lock.fill")
//                            .foregroundStyle(RSMSTheme.Colors.accentGold)
//                            .frame(width: 20)
//
//                        SecureField("", text: $password, prompt: Text("Enter your password").foregroundStyle(RSMSTheme.Colors.textTertiary))
//                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
//                    }
//                    .padding(RSMSTheme.Spacing.lg)
//                    .background(RSMSTheme.Colors.backgroundElevated)
//                    .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
//                            .stroke(RSMSTheme.Colors.border, lineWidth: 1)
//                    )
//                }
//            }
//
//            if isSignUp {
//                // Confirm Password Field
//                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
//                    Text("Confirm Password")
//                        .font(.caption)
//                        .fontWeight(.semibold)
//                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
//                        .textCase(.uppercase)
//
//                    HStack(spacing: RSMSTheme.Spacing.md) {
//                        Image(systemName: "lock.fill")
//                            .foregroundStyle(RSMSTheme.Colors.accentGold)
//                            .frame(width: 20)
//
//                        SecureField("", text: $confirmPassword, prompt: Text("Confirm your password").foregroundStyle(RSMSTheme.Colors.textTertiary))
//                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
//                    }
//                    .padding(RSMSTheme.Spacing.lg)
//                    .background(RSMSTheme.Colors.backgroundElevated)
//                    .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
//                            .stroke(RSMSTheme.Colors.border, lineWidth: 1)
//                    )
//                }
//            }
//
//            if showError {
//                Text(errorMessage)
//                    .font(.caption)
//                    .foregroundStyle(RSMSTheme.Colors.error)
//                    .transition(.opacity)
//            }
//        }
//        .padding(RSMSTheme.Spacing.xl)
//        .background(RSMSTheme.Colors.backgroundDeep.opacity(0.8))
//        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl))
//        .overlay(
//            RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
//                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
//        )
//    }
//
//    // MARK: - Button
//    private var signInButton: some View {
//        VStack(spacing: RSMSTheme.Spacing.md) {
//            Button { attemptLogin() } label: {
//                if isLoading {
//                    ProgressView()
//                        .tint(.white)
//                } else {
//                    Text(isOTPLogin ? "Send Verification Code" : (isSignUp ? "Sign Up" : "Sign In"))
//                }
//            }
//            .buttonStyle(GoldButtonStyle())
//            .disabled(isLoading)
//            
//            if !isOTPLogin {
//                Button {
//                    withAnimation {
//                        isSignUp.toggle()
//                        showError = false
//                        errorMessage = ""
//                    }
//                } label: {
//                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
//                        .font(.footnote)
//                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
//                }
//            }
//        }
//        .fullScreenCover(isPresented: $showOTPVerification) {
//            ManagerOTPView(email: email)
//        }
//    }
//
//    // MARK: - Actions
//    private func attemptLogin() {
//        withAnimation(.easeInOut(duration: 0.3)) { showError = false }
//
//        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
//        guard !trimmedEmail.isEmpty else {
//            withAnimation { showError = true; errorMessage = "Please enter your email address." }
//            return
//        }
//        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
//            withAnimation { showError = true; errorMessage = "Please enter a valid email address." }
//            return
//        }
//        if isOTPLogin {
//            isLoading = true
//            Task {
//                do {
//                    // Check if a role is assigned to this email before sending OTP
//                    let hasRole = try await SupabaseManager.shared.checkEmailRoleExists(email: trimmedEmail)
//                    
//                    if !hasRole {
//                        await MainActor.run {
//                            withAnimation {
//                                showError = true
//                                errorMessage = "No role found for this email. Please contact your Corporate Admin."
//                            }
//                            isLoading = false
//                        }
//                        return
//                    }
//
//                    try await SupabaseManager.shared.sendOTP(email: trimmedEmail)
//                    await MainActor.run {
//                        isLoading = false
//                        showOTPVerification = true
//                    }
//                } catch {
//                    await MainActor.run {
//                        withAnimation {
//                            showError = true
//                            errorMessage = error.localizedDescription
//                        }
//                        isLoading = false
//                    }
//                }
//            }
//            return
//        }
//
//        guard !password.isEmpty else {
//            withAnimation { showError = true; errorMessage = "Please enter your password." }
//            return
//        }
//        
//        if isSignUp {
//            guard password == confirmPassword else {
//                withAnimation { showError = true; errorMessage = "Passwords do not match." }
//                return
//            }
//        }
//        
//        isLoading = true
//        Task {
//            do {
////                #if canImport(Supabase)
//                if isSignUp {
//                    _ = try await SupabaseManager.shared.client.auth.signUp(email: trimmedEmail, password: password)
//                } else {
//                    _ = try await SupabaseManager.shared.client.auth.signIn(email: trimmedEmail, password: password)
//                }
////                #endif  canImport(Supabase)
//                
//                try await appState.login(email: trimmedEmail)
//                await MainActor.run { isLoading = false }
//            } catch {
//                await MainActor.run {
//                    withAnimation {
//                        showError = true
//                        errorMessage = error.localizedDescription
//                    }
//                    isLoading = false
//                }
//            }
//        }
//    }
//
//    
//}
//
//#Preview {
//    LoginView()
//        .environment(AppState())
//}
