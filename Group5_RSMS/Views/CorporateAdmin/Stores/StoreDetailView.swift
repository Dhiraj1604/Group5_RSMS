//
//  StoreDetailView.swift
//  Group5_RSMS
//
//  Corporate Admin — Detail view for a registered boutique.
//

import SwiftUI

struct StoreDetailView: View {
    @Environment(AppState.self) private var appState
    let store: Store
    @State private var showDeleteConfirm = false

    private var liveStore: Store {
        appState.stores.first(where: { $0.id == store.id }) ?? store
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    headerCard
                    detailSection(title: "Location", items: [
                        ("mappin.and.ellipse", "Address", liveStore.formattedAddress),
                        ("map.circle", "Region", liveStore.region),
                    ])
                    detailSection(title: "Contact", items: [
                        ("phone.fill", "Phone", liveStore.phone),
                        ("envelope.fill", "Email", liveStore.email),
                        ("person.fill", "Manager", liveStore.managerName),
                    ])
                    detailSection(title: "Configuration", items: [
                        ("percent", "Tax Rate", liveStore.formattedTaxRate),
                        ("calendar", "Registered", liveStore.createdAt.formatted(date: .abbreviated, time: .shortened)),
                    ])
                    statusToggle
                    deleteButton
                    Spacer().frame(height: RSMSTheme.Spacing.xxl)
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.top, RSMSTheme.Spacing.md)
            }
        }
        .navigationTitle(liveStore.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Header
    private var headerCard: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(liveStore.isActive
                          ? RSMSTheme.Colors.accentGold.opacity(0.15)
                          : RSMSTheme.Colors.textTertiary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(liveStore.isActive
                                     ? RSMSTheme.Colors.accentGold
                                     : RSMSTheme.Colors.textTertiary)
            }
            VStack(spacing: RSMSTheme.Spacing.xs) {
                Text(liveStore.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(liveStore.code)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
            }
            Text(liveStore.isActive ? "● Active" : "● Inactive")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(liveStore.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(
                    (liveStore.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                        .opacity(0.12)
                )
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - Detail Section
    private func detailSection(title: String, items: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: RSMSTheme.Spacing.md) {
                        Image(systemName: item.0)
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.7))
                            .frame(width: 24)
                        Text(item.1)
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        Spacer()
                        Text(item.2)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, RSMSTheme.Spacing.md)
                    if index < items.count - 1 {
                        Divider().background(RSMSTheme.Colors.borderLight)
                    }
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
        }
    }

    // MARK: - Toggle
    private var statusToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                appState.toggleStoreActive(liveStore)
            }
        } label: {
            HStack {
                Image(systemName: liveStore.isActive ? "pause.circle.fill" : "play.circle.fill")
                Text(liveStore.isActive ? "Deactivate Store" : "Activate Store")
            }
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    // MARK: - Delete
    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Store")
            }
            .font(.headline)
            .fontWeight(.medium)
            .foregroundStyle(RSMSTheme.Colors.error)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RSMSTheme.Colors.error.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .stroke(RSMSTheme.Colors.error.opacity(0.3), lineWidth: 1)
            )
        }
        .confirmationDialog("Delete \(liveStore.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { appState.deleteStore(liveStore) }
        } message: {
            Text("This action cannot be undone. All data associated with this store will be permanently removed.")
        }
    }
}

#Preview {
    NavigationStack {
        StoreDetailView(store: Store.sample)
    }
    .environment(AppState())
}
