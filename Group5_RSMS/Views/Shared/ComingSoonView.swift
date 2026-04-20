//
//  ComingSoonView.swift
//  Group5_RSMS
//
//  Blank screen replacement for unbuilt features.
//

import SwiftUI

struct ComingSoonView: View {
    let title: String
    let icon: String
    let description: String

    init(title: String, icon: String = "", description: String = "") {
        self.title = title
        self.icon = icon
        self.description = description
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ComingSoonView(title: "Blank")
}
