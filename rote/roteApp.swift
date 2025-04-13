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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Theme.applyTheme()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
                .onAppear {
                    migrateExistingData()
                }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive {
                try? persistenceController.container.viewContext.save()
            }
        }
    }

    private func migrateExistingData() {
        let context = persistenceController.container.viewContext
        let fetchRequest = NSFetchRequest<Card>(entityName: "Card")
        
        do {
            let cards = try context.fetch(fetchRequest)
            for card in cards {
                card.migrateIfNeeded()
            }
            try context.save()
        } catch {
            print("Migration error: \(error)")
        }
    }
}
