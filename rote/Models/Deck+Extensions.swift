import Foundation
import CoreData

extension Deck {
    var cardArray: [Card] {
        let set = cards as? Set<Card> ?? []
        return Array(set)
    }
    
    var dueCards: [Card] {
        return cardArray.filter { $0.isReadyForReview }
    }
    
    static var defaultFetchRequest: NSFetchRequest<Deck> {
        let request = NSFetchRequest<Deck>(entityName: "Deck")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Deck.createdAt, ascending: false)]
        return request
    }
} 