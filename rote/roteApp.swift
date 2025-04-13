//
//  roteApp.swift
//  rote
//
//  Created by Maxwell Young on 11/04/2025.
//

import SwiftUI

@main
struct RoteApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        Theme.applyTheme()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
        }
    }
}
