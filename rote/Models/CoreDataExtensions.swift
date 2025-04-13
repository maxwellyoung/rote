import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Extensions
public extension NSManagedObject {
    static var entityName: String { String(describing: self) }
    var asCardType: CardType? { self as? CardType }
    var asReviewType: ReviewType? { self as? ReviewType }
}

#if DEBUG
extension NSManagedObject {
    static func debugEntityInfo() {
        print("📋 Core Data Entity Descriptions:")
        guard let modelURL = Bundle.main.url(forResource: "rote", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("❌ Failed to load Core Data model")
            return
        }
        
        model.entities.forEach { entity in
            print("   Entity: \(entity.name ?? "unnamed")")
            print("   Class: \(String(describing: entity.managedObjectClassName))")
            print("   Attributes: \(entity.attributesByName.keys.joined(separator: ", "))")
            print("   Relationships: \(entity.relationshipsByName.keys.joined(separator: ", "))")
            
            if let className = NSClassFromString(entity.managedObjectClassName) {
                print("   Module: \(String(describing: className))")
            } else {
                print("   ❌ Class not found in runtime")
            }
        }
    }
}

// Type information logging
extension Card {
    static func debugTypeInfo() {
        let instance = Card()
        print("🔍 Card Type Information:")
        print("   Self: \(Self.self)")
        print("   Module: \(String(reflecting: Self.self))")
        print("   Superclass: \(String(describing: instance.superclass))")
        print("   Conforms to CardType: \(Self.self is CardType.Type)")
        
        let mirror = Mirror(reflecting: instance)
        print("   Properties: \(mirror.children.map { $0.label ?? "unnamed" }.joined(separator: ", "))")
        
        // Test property access
        print("   Property Access Test:")
        print("   - id: \(String(describing: instance.value(forKey: "id") ?? "nil"))")
        print("   - front: \(String(describing: instance.value(forKey: "front") ?? "nil"))")
        print("   - back: \(String(describing: instance.value(forKey: "back") ?? "nil"))")
    }
}
#endif

// MARK: - Review Extensions
extension Review {
    /// Validates and ensures all required properties are set
    func validateAndSetDefaults() {
        if date == nil {
            date = Date()
        }
        if rating == nil {
            rating = "again" // Default rating
        }
    }
    
    /// Returns a color based on the rating
    var ratingColor: Color {
        guard let rating = rating else { return .gray }
        switch rating {
        case "again":
            return .hex("FF3B30") // Red for error
        case "good":
            return .hex("34C759") // Green for success
        case "easy":
            return .hex("5E5CE6") // Purple for accent
        default:
            return .gray
        }
    }
}

extension Card {
    public override var description: String {
        let cardDescription = """
        Card:
        - ID: \(id?.uuidString ?? "nil")
        - Front: \(front ?? "nil")
        - Back: \(back ?? "nil")
        - Created: \(createdAt?.description ?? "nil")
        - Modified: \(modifiedAt?.description ?? "nil")
        - Last Review: \(lastReviewDate?.description ?? "nil")
        - Due Date: \(dueDate?.description ?? "nil")
        - Review Count: \(reviewCount)
        - Ease: \(ease)
        - Interval: \(interval)
        - Streak: \(streak)
        - Tags: \(tags.joined(separator: ", "))
        """
        return cardDescription
    }
} 
