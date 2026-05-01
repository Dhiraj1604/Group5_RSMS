//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports tab with Revenue Trends, Audit Logs, and Basket Trends.
//

import SwiftUI

struct ReportsTab: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var appeared = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Custom Large Title
                    HStack {
                        Text("Intelligence Reports")
                            .font(.custom("Helvetica-Bold", size: 34))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, 20)
                    
                    // MARK: - Standardized Grid Reports
                    VStack(alignment: .leading, spacing: 20) {
                        Text("AVAILABLE ANALYSIS")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            .tracking(1.5)
                            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                            .padding(.top, 10)
                        
                        let columns = horizontalSizeClass == .regular 
                            ? [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
                            : [GridItem(.flexible(), spacing: 20)]
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            NavigationLink(destination: RevenueTrendsView()) {
                                bentoCard(
                                    title: "Revenue Trends",
                                    subtitle: "Daily, weekly & monthly financial performance with comparisons.",
                                    icon: "chart.bar.xaxis.ascending",
                                    color: RSMSTheme.Colors.accentGold,
                                    isLarge: false
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            NavigationLink(destination: BasketTrendsView()) {
                                bentoCard(
                                    title: "Basket Analysis",
                                    subtitle: "Consumer behavior and average transaction size trends.",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: RSMSTheme.Colors.accentGold,
                                    isLarge: false
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            NavigationLink(destination: AuditLogsView()) {
                                bentoCard(
                                    title: "Audit Logs",
                                    subtitle: "Secure tracking of all administrative actions and changes.",
                                    icon: "shield.lefthalf.filled",
                                    color: RSMSTheme.Colors.accentGold,
                                    isLarge: false
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
            .background {
                ZStack {
                    RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                    
                    // Signature ambient glows
                    Ellipse()
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.06))
                        .blur(radius: 100)
                        .frame(width: 500, height: 400)
                        .offset(x: -200, y: -300)
                    
                    Ellipse()
                        .fill(Color.purple.opacity(0.04))
                        .blur(radius: 120)
                        .frame(width: 600, height: 500)
                        .offset(x: 200, y: 200)
                }
                .ignoresSafeArea()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { appeared = true }
            }
        }
    }
    
    // MARK: - Bento Card Component
    private func bentoCard(title: String, subtitle: String, icon: String, color: Color, isLarge: Bool) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(color)
                }
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(color.opacity(0.3))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.custom("Helvetica-Bold", size: 22))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            if isLarge {
                Spacer()
                // Visual decorative element for large cards
                HStack(spacing: 4) {
                    ForEach(0..<12) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(Double(i) * 0.05))
                            .frame(width: 4, height: 16)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isLarge ? 220 : 180)
        .background {
            ZStack {
                RSMSTheme.Colors.backgroundDeep
                LinearGradient(colors: [color.opacity(0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(colors: [color.opacity(0.4), .clear, color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Animations
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview { ReportsTab() }
