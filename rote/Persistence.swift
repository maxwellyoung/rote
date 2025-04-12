//
//  Persistence.swift
//  rote
//
//  Created by Maxwell Young on 11/04/2025.
//

import CoreData
import SwiftUI

class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Sample programming cards
        createCard(in: viewContext,
                  front: "What is a closure in Swift?",
                  back: "A closure is a self-contained block of functionality that can be passed around and used in your code. It can capture and store references to any constants and variables from the context in which it was defined.",
                  tags: ["swift", "programming"])
        
        createCard(in: viewContext,
                  front: "Explain dependency injection",
                  back: "Dependency injection is a design pattern where objects receive their dependencies from external sources rather than creating them internally. This promotes loose coupling and makes code more testable.",
                  tags: ["programming", "architecture"])
        
        createCard(in: viewContext,
                  front: "Comment dit-on 'hello' en français?",
                  back: "Bonjour",
                  tags: ["french", "greetings"])
        
        createCard(in: viewContext,
                  front: "こんにちは means what in English?",
                  back: "Hello (formal, used during the day)",
                  tags: ["japanese", "greetings"])
        
        createCard(in: viewContext,
                  front: "What is the second law of thermodynamics?",
                  back: "The total entropy of an isolated system always increases over time. Heat flows spontaneously from hot to cold objects, but not the reverse.",
                  tags: ["physics", "thermodynamics"])
        
        createCard(in: viewContext,
                  front: "What is Euler's number (e)?",
                  back: "e ≈ 2.71828... is a mathematical constant that is the base of natural logarithms. It's the limit of (1 + 1/n)^n as n approaches infinity.",
                  tags: ["math", "constants"])
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "rote")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Get the default directory for the app
            let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            // Create a directory for our database if it doesn't exist
            let dataDirectory = storeDirectory.appendingPathComponent("Database", isDirectory: true)
            try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
            
            // Set up the store URL
            let storeURL = dataDirectory.appendingPathComponent("rote.sqlite")
            
            // Configure the persistent store
            let description = NSPersistentStoreDescription(url: storeURL)
            
            // Enable automatic saving
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Basic store configuration first
            container.persistentStoreDescriptions = [description]
        }

        // Load the persistent store
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Handle common Core Data errors
                switch error.code {
                case NSPersistentStoreIncompatibleVersionHashError:
                    // Handle model version mismatch
                    print("⚠️ Core Data model version mismatch. Attempting recovery...")
                    try? FileManager.default.removeItem(at: storeDescription.url!)
                    fatalError("Core Data store had to be recreated due to model mismatch")
                    
                case NSMigrationMissingSourceModelError:
                    // Handle missing model
                    print("⚠️ Core Data source model not found")
                    try? FileManager.default.removeItem(at: storeDescription.url!)
                    fatalError("Core Data source model is missing")
                    
                default:
                    print("⚠️ Unresolved Core Data error: \(error), \(error.userInfo)")
                    try? FileManager.default.removeItem(at: storeDescription.url!)
                    fatalError("Unresolved Core Data error: \(error)")
                }
            }
        }

        // Configure the view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Only set up iCloud sync after basic store is working
        if !inMemory {
            let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourdomain.rote")
            container.persistentStoreDescriptions.first?.cloudKitContainerOptions = cloudKitContainerOptions
        }
    }
    
    // Helper function to save changes
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // Helper function to create sample cards
    private static func createCard(in context: NSManagedObjectContext,
                                 front: String,
                                 back: String,
                                 tags: [String],
                                 interval: Double = 0.0,
                                 ease: Double = 2.5) {
        let card = Card(context: context)
        card.id = UUID()
        card.front = front
        card.back = back
        card.tags = tags
        card.interval = interval
        card.ease = ease
        card.dueDate = Date()
        card.createdAt = Date()
        card.modifiedAt = Date()
        card.streak = 0
        card.reviewCount = 0
        card.lastReviewDate = nil
    }
}
