import Foundation
import CoreData
import SwiftUI

@objc(Card)
public class Card: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var front: String?
    @NSManaged public var back: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var lastReviewDate: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var reviewCount: Int32
    @NSManaged public var ease: Double
    @NSManaged public var interval: Double
    @NSManaged public var streak: Int32
    @NSManaged public var reviewHistory: Any?
    @NSManaged public var tags: [String]
    @NSManaged public var deck: Deck?
    @NSManaged public var reviews: NSSet?
    
    // Review scheduling fields
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var nextReviewAt: Date?
    @NSManaged public var easeFactor: Double // Starts at 2.5, adjusted based on performance
    
    // Review grades
    enum Grade: String {
        case again = "Again"
        case hard = "Hard"
        case good = "Good"
        case easy = "Easy"
        
        var feedback: String {
            switch self {
            case .again:
                return "This thought needs more time to take root. Like a seed in spring, it needs nurturing."
            case .hard:
                return "You're making progress, but this thought needs more attention. Keep nurturing it."
            case .good:
                return "You're building a strong foundation. Each review strengthens your understanding."
            case .easy:
                return "You've engraved this thought in stone. It's now part of your mental landscape."
            }
        }
        
        var multiplier: Double {
            switch self {
            case .again: return 0.0  // Reset to 1 day
            case .hard: return 0.5   // Half the interval
            case .good: return 1.0   // Normal interval
            case .easy: return 1.5   // 1.5x the interval
            }
        }
        
        var easeChange: Double {
            switch self {
            case .again: return -0.2  // Decrease ease
            case .hard: return -0.15  // Slight decrease
            case .good: return 0.0    // No change
            case .easy: return 0.15   // Increase ease
            }
        }
    }
    
    // Add card state enum
    enum State: String {
        case new
        case learning
        case reviewing
        case relearning
    }
    
    // Add learning steps (in minutes)
    static let learningSteps: [TimeInterval] = [1, 10, 60, 240] // 1min, 10min, 1hr, 4hr
    static let relearningSteps: [TimeInterval] = [10, 60] // 10min, 1hr
    
    @NSManaged public var state: String? // Stores State.rawValue
    @NSManaged public var stepIndex: Int32 // Current position in learning/relearning steps
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // Initialize required properties
        id = UUID()
        createdAt = Date()
        modifiedAt = Date()
        
        // Initialize review-related properties
        reviewCount = 0
        ease = 2.5
        interval = 0
        streak = 0
        easeFactor = 2.5
        
        // Initialize dates
        let now = Date()
        dueDate = now
        nextReviewAt = now // Due immediately
        lastReviewedAt = nil
        lastReviewDate = nil
        
        // Initialize collections
        tags = []
        reviewHistory = []
        
        // Initialize learning state
        state = State.new.rawValue
        stepIndex = 0
    }
    
    // Migrate legacy data if needed
    public func migrateIfNeeded() {
        let now = Date()
        
        // Ensure nextReviewAt is set
        if nextReviewAt == nil {
            if let lastReview = lastReviewDate {
                // If we have a last review date, schedule based on that
                nextReviewAt = calculateNextReview(from: lastReview)
            } else {
                // If no review history, due immediately
                nextReviewAt = now
            }
        }
        
        // Ensure easeFactor is set
        if easeFactor == 0 {
            easeFactor = 2.5 // Default ease factor
        }
        
        // Initialize review dates if needed
        if lastReviewedAt == nil {
            lastReviewedAt = lastReviewDate
        }
        
        // Ensure valid interval
        if interval < 0 {
            interval = 0
        }
        
        // Initialize tags if empty
        if tags.isEmpty {
            tags = []
        }
        
        // Save changes
        try? managedObjectContext?.save()
    }
    
    private func calculateNextReview(from lastReview: Date) -> Date {
        let now = Date()
        
        // If the last review was more than 2 weeks ago, reset the card
        let twoWeeks: TimeInterval = 14 * 24 * 60 * 60
        if now.timeIntervalSince(lastReview) > twoWeeks {
            interval = 0
            easeFactor = 2.5
            return now
        }
        
        // Otherwise, schedule based on current interval
        let intervalSeconds = interval * 24 * 60 * 60
        return lastReview.addingTimeInterval(intervalSeconds)
    }
    
    // Helper to reset a card's learning progress
    public func reset() {
        interval = 0
        easeFactor = 2.5
        streak = 0
        nextReviewAt = Date()
        lastReviewedAt = nil
        modifiedAt = Date()
        try? managedObjectContext?.save()
    }
    
    // Validate card state
    public func validate() -> Bool {
        guard id != nil,
              front?.isEmpty == false,
              back?.isEmpty == false,
              createdAt != nil,
              modifiedAt != nil,
              nextReviewAt != nil,
              easeFactor >= 1.3,
              interval >= 0
        else {
            return false
        }
        return true
    }
    
    // Schedule next review based on grade
    func scheduleReview(grade: Grade) {
        let now = Date()
        lastReviewedAt = now
        reviewCount += 1
        
        switch State(rawValue: state ?? "") ?? .new {
        case .new, .learning:
            handleLearningGrade(grade, at: now)
        case .reviewing:
            handleReviewingGrade(grade, at: now)
        case .relearning:
            handleRelearningGrade(grade, at: now)
        }
        
        // Create review record
        let review = Review(context: managedObjectContext!)
        review.date = now
        review.rating = grade.rawValue
        review.ease = easeFactor
        review.interval = interval
        review.card = self
        
        modifiedAt = now
        try? managedObjectContext?.save()
    }
    
    private func handleLearningGrade(_ grade: Grade, at now: Date) {
        switch grade {
        case .again:
            stepIndex = 0
            nextReviewAt = now.addingTimeInterval(Self.learningSteps[0] * 60)
            
        case .hard:
            // Stay at current step
            let stepTime = Self.learningSteps[Int(stepIndex)]
            nextReviewAt = now.addingTimeInterval(stepTime * 60)
            
        case .good:
            stepIndex += 1
            if stepIndex >= Self.learningSteps.count {
                // Graduate to reviewing
                state = State.reviewing.rawValue
                interval = 1
                nextReviewAt = now.addingTimeInterval(24 * 60 * 60) // Tomorrow
            } else {
                // Next learning step
                let stepTime = Self.learningSteps[Int(stepIndex)]
                nextReviewAt = now.addingTimeInterval(stepTime * 60)
            }
            
        case .easy:
            // Graduate immediately to reviewing
            state = State.reviewing.rawValue
            interval = 4
            nextReviewAt = now.addingTimeInterval(4 * 24 * 60 * 60) // 4 days
        }
    }
    
    private func handleReviewingGrade(_ grade: Grade, at now: Date) {
        // Update ease factor
        easeFactor = max(1.3, min(2.5, easeFactor + grade.easeChange))
        
        switch grade {
        case .again:
            // Move to relearning
            state = State.relearning.rawValue
            stepIndex = 0
            interval = 0
            nextReviewAt = now.addingTimeInterval(Self.relearningSteps[0] * 60)
            streak = 0
            
        case .hard:
            interval = max(1, interval * 1.2)
            streak = max(0, streak - 1)
            nextReviewAt = calculateNextReview(interval: interval, at: now)
            
        case .good:
            interval = interval == 0 ? 1 : interval * easeFactor
            streak += 1
            nextReviewAt = calculateNextReview(interval: interval, at: now)
            
        case .easy:
            interval = interval == 0 ? 4 : interval * easeFactor * 1.3
            streak += 1
            nextReviewAt = calculateNextReview(interval: interval, at: now)
        }
    }
    
    private func handleRelearningGrade(_ grade: Grade, at now: Date) {
        switch grade {
        case .again:
            stepIndex = 0
            nextReviewAt = now.addingTimeInterval(Self.relearningSteps[0] * 60)
            
        case .hard:
            // Stay at current step
            let stepTime = Self.relearningSteps[Int(stepIndex)]
            nextReviewAt = now.addingTimeInterval(stepTime * 60)
            
        case .good:
            stepIndex += 1
            if stepIndex >= Self.relearningSteps.count {
                // Back to reviewing
                state = State.reviewing.rawValue
                interval = max(1, interval * 0.5) // Half the previous interval
                nextReviewAt = calculateNextReview(interval: interval, at: now)
            } else {
                // Next relearning step
                let stepTime = Self.relearningSteps[Int(stepIndex)]
                nextReviewAt = now.addingTimeInterval(stepTime * 60)
            }
            
        case .easy:
            // Back to reviewing immediately
            state = State.reviewing.rawValue
            interval = max(2, interval * 0.75) // 75% of previous interval
            nextReviewAt = calculateNextReview(interval: interval, at: now)
        }
    }
    
    private func calculateNextReview(interval: Double, at now: Date) -> Date {
        // Add some randomness to prevent cards clustering
        let jitter = Double.random(in: 0.95...1.05)
        let intervalSeconds = interval * jitter * 24 * 60 * 60
        return now.addingTimeInterval(intervalSeconds)
    }
    
    // Check if card is due for review
    var isDue: Bool {
        guard let nextReview = nextReviewAt else { return true }
        return nextReview <= Date()
    }
    
    // Get review history statistics
    var stats: CardStats {
        let reviews = self.reviews as? Set<Review> ?? []
        let totalReviews = reviews.count
        let correctReviews = reviews.filter { review in
            switch review.rating {
            case "Good", "Easy": return true
            default: return false
            }
        }.count
        
        let averageScore = reviews.reduce(0.0) { total, review in
            let score: Double
            switch review.rating {
            case "Again": score = 0
            case "Hard": score = 1
            case "Good": score = 2
            case "Easy": score = 3
            default: score = 0
            }
            return total + score
        } / Double(max(1, totalReviews))
        
        return CardStats(
            totalReviews: totalReviews,
            correctReviews: correctReviews,
            averageGrade: averageScore,
            retention: Double(correctReviews) / Double(max(1, totalReviews))
        )
    }
}

// Statistics for tracking card performance
struct CardStats {
    let totalReviews: Int
    let correctReviews: Int
    let averageGrade: Double
    let retention: Double
}

// MARK: Generated accessors for reviews
extension Card {
    @objc(addReviewsObject:)
    @NSManaged public func addToReviews(_ value: Review)
    
    @objc(removeReviewsObject:)
    @NSManaged public func removeFromReviews(_ value: Review)
    
    @objc(addReviews:)
    @NSManaged public func addToReviews(_ values: NSSet)
    
    @objc(removeReviews:)
    @NSManaged public func removeFromReviews(_ values: NSSet)
    
    var reviewsArray: [Review] {
        let set = reviews as? Set<Review> ?? []
        return Array(set).sorted { $0.date ?? Date() > $1.date ?? Date() }
    }
}

// MARK: - Fetch Requests
extension Card {
    static var dueCardsFetchRequest: NSFetchRequest<Card> {
        let request = NSFetchRequest<Card>(entityName: "Card")
        request.predicate = NSPredicate(format: "nextReviewAt <= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Card.nextReviewAt, ascending: true)]
        return request
    }
    
    static func dueCardsFetchRequest(tag: String) -> NSFetchRequest<Card> {
        let request = NSFetchRequest<Card>(entityName: "Card")
        request.predicate = NSPredicate(format: "nextReviewAt <= %@ AND ANY tags CONTAINS[c] %@", 
                                      Date() as NSDate, tag)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Card.nextReviewAt, ascending: true)]
        return request
    }
} 