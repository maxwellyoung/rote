import Foundation

public protocol ReviewType {
    var date: Date? { get set }
    var rating: String? { get set }
    var card: CardType? { get set }
} 