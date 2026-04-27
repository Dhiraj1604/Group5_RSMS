//
//  Theme.swift
//  Group5_RSMS
//
//  Centralized design system: colors, fonts, spacing.
//  Luxury dark theme with gold accents on pure black background.
//

import SwiftUI

enum RSMSTheme {
    // MARK: - Colors
    enum Colors {
        // Backgrounds — Deep Brown/Espresso base
        static let backgroundPrimary = Color(red: 0.059, green: 0.043, blue: 0.035)          // #0F0B09 (Espresso)
        static let backgroundDeep = Color(red: 0.102, green: 0.078, blue: 0.071)             // #1A1412 (Rich Mocha)
        static let backgroundElevated = Color(red: 0.149, green: 0.114, blue: 0.102)         // #261D1A (Warm Cocoa)
        static let surfacePrimary = Color(red: 0.118, green: 0.094, blue: 0.086)          // Rich Mahogany Smoke
        
        // Accent — Gold palette
        static let accentGold = Color(red: 0.788, green: 0.663, blue: 0.431)                // #C9A96E
        static let accentGoldLight = Color(red: 0.910, green: 0.835, blue: 0.639)           // #E8D5A3
        static let accentGoldDark = Color(red: 0.659, green: 0.537, blue: 0.243)            // #A8893E

        
        // Status
        static let success = Color(red: 0.30, green: 0.75, blue: 0.45)
        static let warning = Color(red: 0.95, green: 0.75, blue: 0.30)
        static let error = Color(red: 0.85, green: 0.30, blue: 0.30)

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.74, green: 0.69, blue: 0.65)                // Soft Taupe
        static let textTertiary = Color(red: 0.53, green: 0.48, blue: 0.45)

        // Borders
        static let border = Color(red: 0.24, green: 0.20, blue: 0.18)
        static let borderLight = Color(red: 0.18, green: 0.14, blue: 0.12)

        // Gradients
        static let goldGradient = LinearGradient(
            colors: [accentGold, accentGoldDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let backgroundGradient = LinearGradient(
            colors: [backgroundPrimary, backgroundDeep],
            startPoint: .top,
            endPoint: .bottom
        )

        static let cardGradient = LinearGradient(
            colors: [backgroundDeep, backgroundElevated],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let horizontalMargin: CGFloat = 20
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 50
    }
}

// MARK: - Reusable View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RSMSTheme.Colors.goldGradient)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundStyle(RSMSTheme.Colors.accentGold)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.accentGold.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
