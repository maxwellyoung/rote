import Foundation
import CoreData

@objc(Deck)
public class Deck: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var type: String?
    @NSManaged public var topic: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var cards: NSSet?
}

// MARK: Generated accessors for cards
extension Deck {
    @objc(addCardsObject:)
    @NSManaged public func addToCards(_ value: Card)

    @objc(removeCardsObject:)
    @NSManaged public func removeFromCards(_ value: Card)

    @objc(addCards:)
    @NSManaged public func addToCards(_ values: NSSet)

    @objc(removeCards:)
    @NSManaged public func removeFromCards(_ values: NSSet)
} 