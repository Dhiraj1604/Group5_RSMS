//
//  Group5_RSMSApp.swift
//  Group5_RSMS
//
//  Created by Dhiraj on 10/04/26.
//

import SwiftUI

@main
struct Group5_RSMSApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}
