//
//  VIPGuestDetailView.swift
//  Group5_RSMS
//
//  Detailed profile view for a VIP Client, showing preferences, 
//  purchase history, and logged requests.
//

import SwiftUI

struct VIPGuestDetailView: View {
    @ObservedObject var vm: VIPEventViewModel
    let guest: VIPGuest
    
    // Mock purchase history for now
    private let mockPurchases = [
        ("Constella Bracelet", "₹69,000", "12 Oct 2025"),
        ("Maharaja Diamond Ring", "₹5,000,000", "05 Jan 2026")
    ]
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    headerSection
                    
                    if guest.preferences != nil {
                        detailsSection
                    }
                    
                    purchaseHistorySection
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
                .padding(.bottom, RSMSTheme.Spacing.xxl)
            }
        }
        .navigationTitle(guest.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 70, height: 70)
                Text(guest.initials)
                    .font(.title).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.fullName)
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                
                HStack {
                    Image(systemName: guest.tierIcon)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                        .font(.caption)
                    Text("\(guest.tier.capitalized) VIP")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
                
                if let email = guest.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                if let phone = guest.phone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Client Details", icon: "person.text.rectangle.fill")
            
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                if let prefs = guest.preferences {
                    detailRow(label: "Preferences", value: prefs)
                }
                if let last = guest.lastVisit {
                    detailRow(label: "Last Visit", value: last.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    
    private var purchaseHistorySection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            sectionHeader(title: "Purchase History", icon: "bag.fill")
            
            VStack(spacing: 0) {
                ForEach(mockPurchases.indices, id: \.self) { idx in
                    let purchase = mockPurchases[idx]
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(purchase.0)
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Text(purchase.2)
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        }
                        Spacer()
                        Text(purchase.1)
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                    .padding(RSMSTheme.Spacing.md)
                    
                    if idx < mockPurchases.count - 1 {
                        Divider().background(RSMSTheme.Colors.borderLight)
                    }
                }
            }
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    

    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(RSMSTheme.Colors.accentGold)
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption).fontWeight(.bold)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
    }
}
