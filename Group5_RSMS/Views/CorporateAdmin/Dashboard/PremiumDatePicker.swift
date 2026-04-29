//
//  PremiumDatePicker.swift
//  Group5_RSMS
//
//  A high-end, luxury date picker component for the Admin Dashboard.
//  Replaces the standard segmented control with an interactive, animated UI.
//

import SwiftUI

struct PremiumDatePicker: View {
    @Binding var selection: DashboardViewModel.DashboardTimeFrame
    
    var body: some View {
        Picker("Time Frame", selection: $selection) {
            ForEach(DashboardViewModel.DashboardTimeFrame.allCases) { timeFrame in
                Text(timeFrame.rawValue)
                    .tag(timeFrame)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
        PremiumDatePicker(selection: .constant(.last30Days))
            .padding()
    }
}
