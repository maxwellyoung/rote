import Foundation

struct BuiltInCard {
    let front: String
    let back: String
    let tags: [String]
}

struct BuiltInDeck {
    let id: String
    let name: String
    let description: String
    let category: DeckCategory
    let cards: [BuiltInCard]
    let imageSystemName: String
    
    enum DeckCategory: String {
        case computerScience = "Computer Science"
        case softwareEngineering = "Software Engineering"
        case mathematics = "Mathematics"
        case learning = "Learning & Study Skills"
    }
}

// Built-in decks data
extension BuiltInDeck {
    static let allDecks: [BuiltInDeck] = [
        BuiltInDeck(
            id: "dsa-basics",
            name: "Data Structures & Algorithms Basics",
            description: "Essential concepts in DSA including Big O notation, arrays, linked lists, trees, and basic algorithms.",
            category: .computerScience,
            cards: [
                BuiltInCard(
                    front: "What is Big O notation?",
                    back: "Big O notation describes the upper bound of the growth rate of an algorithm's time or space complexity. It helps us understand how the algorithm's performance scales with input size.",
                    tags: ["dsa", "complexity"]
                ),
                BuiltInCard(
                    front: "What is the time complexity of binary search?",
                    back: "O(log n) - The algorithm repeatedly divides the search space in half, resulting in logarithmic time complexity.",
                    tags: ["dsa", "algorithms", "searching"]
                ),
                // Add more cards...
            ],
            imageSystemName: "chart.bar.xaxis"
        ),
        BuiltInDeck(
            id: "swe-principles",
            name: "Software Engineering Principles",
            description: "Core principles of software engineering including SOLID, design patterns, and best practices.",
            category: .softwareEngineering,
            cards: [
                BuiltInCard(
                    front: "What is the Single Responsibility Principle?",
                    back: "A class should have only one reason to change, meaning it should have only one job or responsibility. This principle helps create more maintainable and flexible code.",
                    tags: ["solid", "principles"]
                ),
                BuiltInCard(
                    front: "What is the Strategy Pattern?",
                    back: "A behavioral design pattern that enables selecting an algorithm's implementation at runtime. It defines a family of algorithms, encapsulates each one, and makes them interchangeable.",
                    tags: ["design-patterns", "behavioral"]
                ),
                // Add more cards...
            ],
            imageSystemName: "hammer.fill"
        ),
        BuiltInDeck(
            id: "learning-techniques",
            name: "Learning How to Learn",
            description: "Evidence-based learning techniques and memory strategies for effective studying.",
            category: .learning,
            cards: [
                BuiltInCard(
                    front: "What is spaced repetition?",
                    back: "A learning technique where review sessions are spaced out over time, with increasing intervals between reviews. This method optimizes long-term retention by reviewing items just before they would be forgotten.",
                    tags: ["learning", "memory"]
                ),
                BuiltInCard(
                    front: "What is the Pomodoro Technique?",
                    back: "A time management method using 25-minute focused work sessions (pomodoros) followed by short breaks. This technique helps maintain concentration and prevent mental fatigue.",
                    tags: ["productivity", "study-methods"]
                ),
                // Add more cards...
            ],
            imageSystemName: "brain.head.profile"
        )
    ]
} 