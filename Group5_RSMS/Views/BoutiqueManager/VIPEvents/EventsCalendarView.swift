//
//  EventsCalendarView.swift
//  Group5_RSMS
//

import SwiftUI

struct EventsCalendarView: View {
    @ObservedObject var viewModel: VIPEventsViewModel
    @State private var showingCreateEvent = false
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Create Event Button
                    Button {
                        showingCreateEvent = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Event")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.backgroundPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RSMSTheme.Colors.accentGold)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    
                    // Events List
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.events) { event in
                            NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                                EventRow(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventSheet(viewModel: viewModel)
        }
    }
}

struct EventRow: View {
    let event: VIPEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                
                Spacer()
                
                if event.isFull {
                    Text("FULL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RSMSTheme.Colors.error)
                        .clipShape(Capsule())
                } else {
                    Text("\(event.rsvps.count)/\(event.capacity) RSVP")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
            
            Text(event.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            
            if !event.collectionDetails.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                    Text(event.collectionDetails.joined(separator: ", "))
                        .font(.system(size: 13))
                        .lineLimit(1)
                }
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}
