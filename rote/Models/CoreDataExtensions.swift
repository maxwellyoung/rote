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
            print("   Class: \(entity.managedObjectClassName)")
            print("   Attributes: \(entity.attributesByName.keys.joined(separator: ", "))")
            print("   Relationships: \(entity.relationshipsByName.keys.joined(separator: ", "))")
            
            // Add module information
            if let className = NSClassFromString(entity.managedObjectClassName) {
                print("   Module: \(className.self)")
            } else {
                print("   ❌ Class not found in runtime")
            }
        }
    }
}

// Type information logging
extension Card {
    static func debugTypeInfo() {
        print("🔍 Card Type Information:")
        print("   Self: \(Self.self)")
        print("   Module: \(String(reflecting: Self.self))")
        print("   Superclass: \(String(describing: Self.superclass))")
        print("   Conforms to CardType: \(Self.self is CardType.Type)")
        
        let mirror = Mirror(reflecting: Card())
        print("   Properties: \(mirror.children.map { $0.label ?? "unnamed" }.joined(separator: ", "))")
        
        // Test property access
        let testCard = Card()
        print("   Property Access Test:")
        print("   - id: \(String(describing: testCard.value(forKey: "id")))")
        print("   - front: \(String(describing: testCard.value(forKey: "front")))")
        print("   - back: \(String(describing: testCard.value(forKey: "back")))")
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
