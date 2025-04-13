import Foundation
import CoreData

@objc(Review)
public class Review: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var rating: String?
    @NSManaged public var ease: Double
    @NSManaged public var interval: Double
    @NSManaged public var card: Card?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        date = Date()
        ease = 2.5
        interval = 0
    }
} 