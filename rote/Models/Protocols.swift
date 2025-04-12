import Foundation
import CoreData

// MARK: - Protocols
public protocol CardType {
    var id: UUID? { get set }
    var front: String? { get set }
    var back: String? { get set }
    var tags: [String]? { get set }
    var createdAt: Date? { get set }
    var modifiedAt: Date? { get set }
    var lastReviewDate: Date? { get set }
    var dueDate: Date? { get set }
    var ease: Double { get set }
    var interval: Double { get set }
    var streak: Int32 { get set }
    var reviewCount: Int32 { get set }
    var reviews: NSSet? { get set }
    var reviewsArray: [Review] { get }
    var tagsArray: [String] { get }
    var reviewHistoryArray: [[String: Any]] { get }
    var isDue: Bool { get }
    var timeSinceLastReview: TimeInterval? { get }
    var retentionScore: Double { get }
    func validateAndSetDefaults()
} 