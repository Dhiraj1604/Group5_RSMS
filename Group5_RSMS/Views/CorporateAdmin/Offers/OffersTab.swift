//
//  OffersTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Offers tab.
//  Wraps OffersView in a NavigationStack.
//

import SwiftUI

struct OffersTab: View {
    var body: some View {
        NavigationStack {
            OffersView()
        }
    }
}

#Preview { OffersTab() }
