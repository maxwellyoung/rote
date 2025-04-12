import SwiftUI
import CoreData

class CardViewModel: ObservableObject {
    @Published var front: String = ""
    @Published var back: String = ""
    @Published var tags: [String] = []
    
    var isValid: Bool {
        !front.isEmpty && !back.isEmpty
    }
    
    func reset() {
        front = ""
        back = ""
        tags = []
    }
    
    func saveCard(context: NSManagedObjectContext) throws {
        let card = Card(context: context)
        card.id = UUID()
        card.front = front
        card.back = back
        card.tags = tags
        card.createdAt = Date()
        card.modifiedAt = Date()
        card.interval = 0
        card.ease = 2.5
        card.streak = 0
        card.reviewCount = 0
        card.dueDate = Date()
        
        try context.save()
    }
} 