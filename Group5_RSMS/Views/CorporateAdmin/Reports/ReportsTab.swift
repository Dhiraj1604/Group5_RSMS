//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports hub with premium card-based navigation.
//  Optimized for iPad with a responsive 2-column grid layout.
//

import SwiftUI

struct ReportsTab: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        horizontalSizeClass == .regular
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible(), spacing: 16)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xl) {


                        // Report cards grid
                        LazyVGrid(columns: columns, spacing: 16) {

                            // Revenue Trends
                            NavigationLink(destination: RevenueTrendsView()) {
                                reportCard(
                                    icon: "chart.bar.xaxis.ascending",
                                    title: "Revenue Trends",
                                    subtitle: "Track daily, weekly & monthly revenue with period comparison and export.",
                                    tag: "Financial"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Basket Size Trends
                            NavigationLink(destination: BasketTrendsView()) {
                                reportCard(
                                    icon: "basket.fill",
                                    title: "Basket Trends",
                                    subtitle: "Analyze average items per transaction across stores and categories.",
                                    tag: "Transactions"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Sales Transactions
                            NavigationLink(destination: SalesTransactionsView()) {
                                reportCard(
                                    icon: "receipt.fill",
                                    title: "Sales Transactions",
                                    subtitle: "Browse individual transactions with store, items, amount and full breakdown.",
                                    tag: "Sales"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Audit Logs
                            NavigationLink(destination: AuditLogsView()) {
                                reportCard(
                                    icon: "shield.lefthalf.filled",
                                    title: "Audit Logs",
                                    subtitle: "Complete trail of admin actions — products, tax, offers, stores & users.",
                                    tag: "Compliance"

//     @Environment(\.horizontalSizeClass) private var horizontalSizeClass
//     @State private var appeared = false
    
//     var body: some View {
//         NavigationStack {
//             ScrollView {
//                 VStack(spacing: 32) {
//                     // Custom Large Title
//                     HStack {
//                         Text("Intelligence Reports")
//                             .font(.custom("Helvetica-Bold", size: 34))
//                             .foregroundStyle(.white)
//                         Spacer()
//                     }
//                     .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
//                     .padding(.top, 20)
                    
//                     // MARK: - Standardized Grid Reports
//                     VStack(alignment: .leading, spacing: 20) {
//                         Text("AVAILABLE ANALYSIS")
//                             .font(.system(size: 12, weight: .bold))
//                             .foregroundStyle(RSMSTheme.Colors.textTertiary)
//                             .tracking(1.5)
//                             .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
//                             .padding(.top, 10)
                        
//                         let columns = horizontalSizeClass == .regular 
//                             ? [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
//                             : [GridItem(.flexible(), spacing: 20)]
                        
//                         LazyVGrid(columns: columns, spacing: 20) {
//                             NavigationLink(destination: RevenueTrendsView()) {
//                                 bentoCard(
//                                     title: "Revenue Trends",
//                                     subtitle: "Daily, weekly & monthly financial performance with comparisons.",
//                                     icon: "chart.bar.xaxis.ascending",
//                                     color: RSMSTheme.Colors.accentGold,
//                                     isLarge: false
//                                 )
//                             }
//                             .buttonStyle(ScaleButtonStyle())
                            
//                             NavigationLink(destination: BasketTrendsView()) {
//                                 bentoCard(
//                                     title: "Basket Analysis",
//                                     subtitle: "Consumer behavior and average transaction size trends.",
//                                     icon: "chart.line.uptrend.xyaxis",
//                                     color: RSMSTheme.Colors.accentGold,
//                                     isLarge: false
//                                 )
//                             }
//                             .buttonStyle(ScaleButtonStyle())
                            
//                             NavigationLink(destination: AuditLogsView()) {
//                                 bentoCard(
//                                     title: "Audit Intelligence",
//                                     subtitle: "Secure tracking of all administrative actions and changes.",
//                                     icon: "shield.lefthalf.filled",
//                                     color: RSMSTheme.Colors.accentGold,
//                                     isLarge: false
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.lg)
                    .padding(.bottom, 60)
//                         .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
//                     }
                    
//                     Spacer().frame(height: 100)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Report Card

    private func reportCard(
        icon: String,
        title: String,
        subtitle: String,
        tag: String
    ) -> some View {
        let accent = RSMSTheme.Colors.accentGold
        return VStack(alignment: .leading, spacing: 0) {

            // Top accent bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.8), accent.opacity(0.15)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 3)

            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                // Icon + Tag row
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.12))
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accent.opacity(0.2), lineWidth: 0.5)
                            )
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accent, accent.opacity(0.7)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }

                    Spacer()

                    // Tag pill
                    Text(tag.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.1))
                        .cornerRadius(6)
                }

                // Title
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Chevron
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.6))
                }
            }
            .padding(RSMSTheme.Spacing.lg)
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(accent.opacity(0.15), lineWidth: 0.5)
        )
        .shadow(color: accent.opacity(0.06), radius: 12, x: 0, y: 6)

    
    // MARK: - Bento Card Component
//     private func bentoCard(title: String, subtitle: String, icon: String, color: Color, isLarge: Bool) -> some View {
//         VStack(alignment: .leading, spacing: 20) {
//             HStack {
//                 ZStack {
//                     Circle()
//                         .fill(color.opacity(0.12))
//                         .frame(width: 44, height: 44)
//                     Image(systemName: icon)
//                         .font(.system(size: 18, weight: .bold))
//                         .foregroundStyle(color)
//                 }
//                 Spacer()
//                 Image(systemName: "arrow.up.right.circle.fill")
//                     .font(.title3)
//                     .foregroundStyle(color.opacity(0.3))
//             }
            
//             VStack(alignment: .leading, spacing: 8) {
//                 Text(title)
//                     .font(.custom("Helvetica-Bold", size: 22))
//                     .foregroundStyle(.white)
                
//                 Text(subtitle)
//                     .font(.system(size: 14))
//                     .foregroundStyle(RSMSTheme.Colors.textSecondary)
//                     .lineLimit(2)
//                     .multilineTextAlignment(.leading)
//             }
            
//             if isLarge {
//                 Spacer()
//                 // Visual decorative element for large cards
//                 HStack(spacing: 4) {
//                     ForEach(0..<12) { i in
//                         RoundedRectangle(cornerRadius: 2)
//                             .fill(color.opacity(Double(i) * 0.05))
//                             .frame(width: 4, height: 16)
//                     }
//                 }
//             }
//         }
//         .padding(24)
//         .frame(maxWidth: .infinity, alignment: .leading)
//         .frame(height: isLarge ? 220 : 180)
//         .background {
//             ZStack {
//                 RSMSTheme.Colors.backgroundDeep
//                 LinearGradient(colors: [color.opacity(0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
//             }
//         }
//         .cornerRadius(24)
//         .overlay(
//             RoundedRectangle(cornerRadius: 24)
//                 .stroke(
//                     LinearGradient(colors: [color.opacity(0.4), .clear, color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
//                     lineWidth: 1
//                 )
//         )
//         .shadow(color: color.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview { ReportsTab().environment(AppState()) }
