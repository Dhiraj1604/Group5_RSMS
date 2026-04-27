//
//  EventDetailView.swift
//  Group5_RSMS
//

import SwiftUI

struct EventDetailView: View {
    let event: VIPEvent
    @ObservedObject var viewModel: VIPEventsViewModel
    
    // Using a local state to refresh the view immediately after RSVP
    @State private var localRSVPs: [EventRSVP]
    
    init(event: VIPEvent, viewModel: VIPEventsViewModel) {
        self.event = event
        self.viewModel = viewModel
        _localRSVPs = State(initialValue: event.rsvps)
    }
    
    var isFull: Bool {
        return localRSVPs.count >= event.capacity
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    headerSection
                    capacitySection
                    collectionSection
                    
                    Spacer(minLength: 40)
                    
                    // Simulate RSVP Button
                    Button {
                        simulateRSVP()
                    } label: {
                        Text(isFull ? "Event is Full" : "Simulate RSVP")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isFull ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(isFull ? RSMSTheme.Colors.surfacePrimary : RSMSTheme.Colors.accentGold)
                            .cornerRadius(12)
                    }
                    .disabled(isFull)
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "star.fill")
                    .font(.system(size: 28))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            
            Text(event.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(event.date.formatted(date: .complete, time: .shortened))
                .font(.system(size: 14))
                .foregroundColor(RSMSTheme.Colors.accentGold)
        }
    }
    
    private var capacitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("RSVP Status")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                if isFull {
                    Text("FULL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RSMSTheme.Colors.error)
                        .clipShape(Capsule())
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Guests")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Text("\(localRSVPs.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Capacity")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Text("\(event.capacity)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                }
            }
            .padding(16)
            .background(RSMSTheme.Colors.backgroundElevated)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            
            // Progress Bar
            GeometryReader { geo in
                let pct = min(Double(localRSVPs.count) / Double(event.capacity), 1.0)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(RSMSTheme.Colors.surfacePrimary).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isFull ? RSMSTheme.Colors.error : RSMSTheme.Colors.accentGold)
                        .frame(width: geo.size.width * pct, height: 6)
                        .animation(.easeOut, value: pct)
                }
            }
            .frame(height: 6)
            .padding(.top, 8)
        }
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
    }
    
    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Collections")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            
            if event.collectionDetails.isEmpty {
                Text("No collections linked.")
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                    ForEach(event.collectionDetails, id: \.self) { item in
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                            Text(item)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                .lineLimit(2)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RSMSTheme.Colors.surfacePrimary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
    }
    
    private func simulateRSVP() {
        if viewModel.rsvpForEvent(eventId: event.id, clientName: "Test RSVP Guest") {
            // Update local state to immediately refresh UI
            if let updatedEvent = viewModel.events.first(where: { $0.id == event.id }) {
                localRSVPs = updatedEvent.rsvps
            }
        }
    }
}
