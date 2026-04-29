//
//  Theme.swift
//  Group5_RSMS
//
//  Centralized design system: colors, fonts, spacing.
//  Luxury dark theme with gold accents on pure black background.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum RSMSAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum RSMSTheme {
    // MARK: - Colors
    enum Colors {
        static let backgroundPrimary = adaptiveColor(
            dark: UIColor(red: 0.059, green: 0.043, blue: 0.035, alpha: 1),
            darkHighContrast: UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1),
            light: UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1), // Light gray/beige
            lightHighContrast: UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        )
        static let backgroundDeep = adaptiveColor(
            dark: UIColor(red: 0.102, green: 0.078, blue: 0.071, alpha: 1),
            darkHighContrast: UIColor(red: 0.045, green: 0.045, blue: 0.045, alpha: 1),
            light: UIColor(red: 0.92, green: 0.91, blue: 0.89, alpha: 1), // Darker gray/beige
            lightHighContrast: UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
        )
        static let backgroundElevated = adaptiveColor(
            dark: UIColor(red: 0.149, green: 0.114, blue: 0.102, alpha: 1),
            darkHighContrast: UIColor(red: 0.090, green: 0.090, blue: 0.090, alpha: 1),
            light: UIColor.white, // Pure white for cards in light mode
            lightHighContrast: UIColor.white
        )
        static let surfacePrimary = adaptiveColor(
            dark: UIColor(red: 0.118, green: 0.094, blue: 0.086, alpha: 1),
            darkHighContrast: UIColor(red: 0.070, green: 0.070, blue: 0.070, alpha: 1),
            light: UIColor(red: 0.984, green: 0.973, blue: 0.949, alpha: 1),
            lightHighContrast: UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1)
        )

        static let accentGold = adaptiveColor(
            dark: UIColor(red: 0.788, green: 0.663, blue: 0.431, alpha: 1),
            darkHighContrast: UIColor(red: 1.000, green: 0.816, blue: 0.290, alpha: 1),
            light: UIColor(red: 0.506, green: 0.373, blue: 0.094, alpha: 1),
            lightHighContrast: UIColor(red: 0.388, green: 0.263, blue: 0.000, alpha: 1)
        )
        static let accentGoldLight = adaptiveColor(
            dark: UIColor(red: 0.910, green: 0.835, blue: 0.639, alpha: 1),
            darkHighContrast: UIColor(red: 1.000, green: 0.925, blue: 0.580, alpha: 1),
            light: UIColor(red: 0.373, green: 0.263, blue: 0.055, alpha: 1),
            lightHighContrast: UIColor(red: 0.263, green: 0.169, blue: 0.000, alpha: 1)
        )
        static let accentGoldDark = adaptiveColor(
            dark: UIColor(red: 0.659, green: 0.537, blue: 0.243, alpha: 1),
            darkHighContrast: UIColor(red: 0.941, green: 0.714, blue: 0.141, alpha: 1),
            light: UIColor(red: 0.447, green: 0.314, blue: 0.055, alpha: 1),
            lightHighContrast: UIColor(red: 0.314, green: 0.204, blue: 0.000, alpha: 1)
        )

        static let success = adaptiveColor(
            dark: UIColor(red: 0.300, green: 0.750, blue: 0.450, alpha: 1),
            darkHighContrast: UIColor(red: 0.220, green: 0.950, blue: 0.420, alpha: 1),
            light: UIColor(red: 0.000, green: 0.420, blue: 0.180, alpha: 1),
            lightHighContrast: UIColor(red: 0.000, green: 0.300, blue: 0.120, alpha: 1)
        )
        static let warning = adaptiveColor(
            dark: UIColor(red: 0.950, green: 0.750, blue: 0.300, alpha: 1),
            darkHighContrast: UIColor(red: 1.000, green: 0.840, blue: 0.000, alpha: 1),
            light: UIColor(red: 0.620, green: 0.380, blue: 0.000, alpha: 1),
            lightHighContrast: UIColor(red: 0.450, green: 0.250, blue: 0.000, alpha: 1)
        )
        static let error = adaptiveColor(
            dark: UIColor(red: 0.850, green: 0.300, blue: 0.300, alpha: 1),
            darkHighContrast: UIColor(red: 1.000, green: 0.360, blue: 0.360, alpha: 1),
            light: UIColor(red: 0.720, green: 0.000, blue: 0.000, alpha: 1),
            lightHighContrast: UIColor(red: 0.540, green: 0.000, blue: 0.000, alpha: 1)
        )

        static let textPrimary = adaptiveColor(
            dark: UIColor.white,
            darkHighContrast: UIColor.white,
            light: UIColor(red: 0.055, green: 0.043, blue: 0.035, alpha: 1),
            lightHighContrast: UIColor.black
        )
        static let textSecondary = adaptiveColor(
            dark: UIColor(red: 0.740, green: 0.690, blue: 0.650, alpha: 1),
            darkHighContrast: UIColor(red: 0.910, green: 0.890, blue: 0.850, alpha: 1),
            light: UIColor(red: 0.310, green: 0.270, blue: 0.235, alpha: 1),
            lightHighContrast: UIColor(red: 0.120, green: 0.120, blue: 0.120, alpha: 1)
        )
        static let textTertiary = adaptiveColor(
            dark: UIColor(red: 0.530, green: 0.480, blue: 0.450, alpha: 1),
            darkHighContrast: UIColor(red: 0.760, green: 0.730, blue: 0.690, alpha: 1),
            light: UIColor(red: 0.420, green: 0.370, blue: 0.330, alpha: 1),
            lightHighContrast: UIColor(red: 0.220, green: 0.220, blue: 0.220, alpha: 1)
        )

        static let border = adaptiveColor(
            dark: UIColor(red: 0.240, green: 0.200, blue: 0.180, alpha: 1),
            darkHighContrast: UIColor(red: 0.650, green: 0.650, blue: 0.650, alpha: 1),
            light: UIColor(red: 0.760, green: 0.710, blue: 0.650, alpha: 1),
            lightHighContrast: UIColor(red: 0.260, green: 0.260, blue: 0.260, alpha: 1)
        )
        static let borderLight = adaptiveColor(
            dark: UIColor(red: 0.180, green: 0.140, blue: 0.120, alpha: 1),
            darkHighContrast: UIColor(red: 0.520, green: 0.520, blue: 0.520, alpha: 1),
            light: UIColor(red: 0.840, green: 0.800, blue: 0.740, alpha: 1),
            lightHighContrast: UIColor(red: 0.360, green: 0.360, blue: 0.360, alpha: 1)
        )

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

        private static func adaptiveColor(
            dark: UIColor,
            darkHighContrast: UIColor,
            light: UIColor,
            lightHighContrast: UIColor
        ) -> Color {
            Color(UIColor { traits in
                let isHighContrast = traits.accessibilityContrast == .high
                let isDark = traits.userInterfaceStyle == .dark

                switch (isDark, isHighContrast) {
                case (true, true): return darkHighContrast
                case (true, false): return dark
                case (false, true): return lightHighContrast
                case (false, false): return light
                }
            })
        }
    }

    // MARK: - Typography
    enum Typography {
        static let heading1 = Font.system(size: 34, weight: .bold, design: .rounded)
        static let heading2 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let heading3 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let heading4 = Font.system(size: 18, weight: .semibold, design: .rounded)
        
        static let bodyCopy1 = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyCopy2 = Font.system(size: 14, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let button = Font.system(size: 16, weight: .bold, design: .default)
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
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
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
