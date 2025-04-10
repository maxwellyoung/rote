//
//  Persistence.swift
//  rote
//
//  Created by Maxwell Young on 11/04/2025.
//

import CoreData
import SwiftUI

struct PersistenceController {
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
        
        // Configure the persistent store
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
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            container.persistentStoreDescriptions = [description]
        }
        
        // Load the persistent stores
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error details
                print("Error loading persistent store: \(error), \(error.userInfo)")
                
                // Handle common errors
                switch error.code {
                case NSPersistentStoreIncompatibleVersionHashError:
                    // Handle model version mismatch
                    print("⚠️ Incompatible model version. Migration needed.")
                case NSMigrationMissingSourceModelError:
                    // Handle missing model
                    print("⚠️ Missing source model.")
                default:
                    print("⚠️ Unhandled error: \(error.localizedDescription)")
                }
                
                // In development, we might want to delete the store and start fresh
                #if DEBUG
                try? FileManager.default.removeItem(at: storeDescription.url!)
                fatalError("Unresolved Core Data error: \(error)")
                #else
                // In production, we should handle this more gracefully
                print("⚠️ Core Data store error. The app will continue with an empty store.")
                #endif
            }
        }
        
        // Configure the view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up automatic saving
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.save()
        }
        #endif
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
