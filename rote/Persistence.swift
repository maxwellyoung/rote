//
//  Persistence.swift
//  rote
//
//  Created by Maxwell Young on 11/04/2025.
//

import CoreData

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
        
        // Sample language cards
        createCard(in: viewContext,
                  front: "Comment dit-on 'hello' en français?",
                  back: "Bonjour",
                  tags: ["french", "greetings"])
        
        createCard(in: viewContext,
                  front: "こんにちは means what in English?",
                  back: "Hello (formal, used during the day)",
                  tags: ["japanese", "greetings"])
        
        // Sample science cards
        createCard(in: viewContext,
                  front: "What is the second law of thermodynamics?",
                  back: "The total entropy of an isolated system always increases over time. Heat flows spontaneously from hot to cold objects, but not the reverse.",
                  tags: ["physics", "thermodynamics"])
        
        // Sample math cards
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
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
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
    }
}
