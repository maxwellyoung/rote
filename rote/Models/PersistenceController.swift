import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create preview content
        let viewContext = controller.container.viewContext
        BuiltInDecks.createBuiltInDecks(context: viewContext)
        
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Rote")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Check if this is the first launch
        if UserDefaults.standard.bool(forKey: "didCreateBuiltInDecks") == false {
            BuiltInDecks.createBuiltInDecks(context: container.viewContext)
            UserDefaults.standard.set(true, forKey: "didCreateBuiltInDecks")
        }
    }
} 