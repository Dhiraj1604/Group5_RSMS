//
//  VIPEventsListView.swift
//  Group5_RSMS
//
//  Events list — Upcoming and Past sections.
//  Tap any event to open VIPEventDetailView.
//

import SwiftUI

struct VIPEventsListView: View {
    @ObservedObject var vm: VIPEventViewModel
    let boutiqueId: UUID

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if vm.isLoadingEvents {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.events.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !vm.upcomingEvents.isEmpty {
                            sectionHeader("Upcoming & Ongoing")
                            ForEach(vm.upcomingEvents) { event in
                                NavigationLink(destination:
                                    VIPEventDetailView(vm: vm, event: event)
                                ) {
                                    EventCard(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if !vm.pastEvents.isEmpty {
                            sectionHeader("Past Events")
                            ForEach(vm.pastEvents) { event in
                                NavigationLink(destination:
                                    VIPEventDetailView(vm: vm, event: event)
                                ) {
                                    EventCard(event: event, dimmed: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Spacer().frame(height: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 52))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No VIP Events Yet")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Text("Tap + to create your first exclusive event.")
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(RSMSTheme.Colors.textSecondary)
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: VIPEvent
    var dimmed: Bool = false

    private var statusColor: Color {
        switch event.status {
        case "upcoming":  return RSMSTheme.Colors.accentGold
        case "completed": return RSMSTheme.Colors.textTertiary
        default:          return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    if let theme = event.theme {
                        Text("Theme: \(theme)")
                            .font(.caption)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                }
                Spacer()
                // Status badge
                Text(event.statusDisplay)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Divider().background(RSMSTheme.Colors.borderLight)

            // Detail rows
            HStack(spacing: 16) {
                Label(event.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                if let cap = event.guestCapacity {
                    Label("\(cap) max", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }

            if let venue = event.venue {
                Label(venue, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    event.status == "upcoming"
                        ? RSMSTheme.Colors.accentGold.opacity(0.3)
                        : RSMSTheme.Colors.borderLight,
                    lineWidth: 1
                )
        )
        .opacity(dimmed ? 0.65 : 1)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}
