//
//  roteApp.swift
//  rote
//
//  Created by Maxwell Young on 11/04/2025.
//

import SwiftUI

@main
struct roteApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
