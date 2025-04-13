import Foundation
import CoreData

extension Card {
    var isReadyForReview: Bool {
        guard let dueDate = dueDate else { return true }
        return Date() >= dueDate
    }
    
    func updateNextReview(rating: String) {
        // Simple spaced repetition algorithm
        let intervals: [TimeInterval] = [
            86400,    // 1 day
            172800,   // 2 days
            432000,   // 5 days
            864000,   // 10 days
            2592000,  // 30 days
            7776000,  // 90 days
            15552000  // 180 days
        ]
        
        // Adjust ease based on rating
        switch rating.lowercased() {
        case "again":
            ease = max(1.3, ease - 0.2)
            interval = 0
            streak = 0
        case "hard":
            ease = max(1.3, ease - 0.15)
            interval *= 1.2
            streak += 1
        case "good":
            interval *= ease
            streak += 1
        case "easy":
            ease = min(2.5, ease + 0.15)
            interval *= ease * 1.3
            streak += 1
        default:
            break
        }
        
        // Calculate next review date
        if interval == 0 {
            interval = intervals[0]
        } else {
            interval = min(interval, intervals.last ?? 15552000)
        }
        
        dueDate = Date().addingTimeInterval(interval)
        lastReviewDate = Date()
        reviewCount += 1
        
        // Store review history
        let review: [String: Any] = [
            "date": Date(),
            "rating": rating,
            "interval": interval,
            "ease": ease
        ]
        
        if var history = reviewHistory as? [[String: Any]] {
            history.append(review)
            reviewHistory = history
        } else {
            reviewHistory = [review]
        }
    }
    
    static var defaultFetchRequest: NSFetchRequest<Card> {
        let request = NSFetchRequest<Card>(entityName: "Card")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Card.createdAt, ascending: false)]
        return request
    }
} 