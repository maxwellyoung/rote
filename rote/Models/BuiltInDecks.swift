import Foundation
import CoreData

enum BuiltInDeckType: String, CaseIterable {
    case swiftFundamentals = "Swift Fundamentals"
    case swiftUI = "SwiftUI Essentials"
    case designPatterns = "Design Patterns"
    case algorithms = "Algorithms & Data Structures"
    case systemDesign = "iOS System Design"
    case networking = "Networking & REST"
    case testing = "Testing Best Practices"
    case performance = "iOS Performance"
    
    var description: String {
        switch self {
        case .swiftFundamentals:
            return "Master the core concepts of Swift programming language"
        case .swiftUI:
            return "Learn modern iOS development with SwiftUI framework"
        case .designPatterns:
            return "Common software design patterns in iOS development"
        case .algorithms:
            return "Essential algorithms and data structures for iOS developers"
        case .systemDesign:
            return "Architecture and system design principles for iOS apps"
        case .networking:
            return "Networking concepts, REST APIs, and data handling"
        case .testing:
            return "Unit testing, UI testing, and test-driven development"
        case .performance:
            return "iOS app performance optimization and best practices"
        }
    }
    
    var icon: String {
        switch self {
        case .swiftFundamentals: return "swift"
        case .swiftUI: return "rectangle.3.group"
        case .designPatterns: return "pentagon.path"
        case .algorithms: return "chart.bar.xaxis"
        case .systemDesign: return "square.3.layers.3d"
        case .networking: return "network"
        case .testing: return "checkmark.circle"
        case .performance: return "gauge"
        }
    }
}

struct BuiltInDecks {
    static func createBuiltInDecks(context: NSManagedObjectContext) {
        for deckType in BuiltInDeckType.allCases {
            createDeck(type: deckType, context: context)
        }
    }
    
    private static func createDeck(type: BuiltInDeckType, context: NSManagedObjectContext) {
        let deck = Deck(context: context)
        deck.id = UUID()
        deck.title = type.rawValue
        deck.desc = type.description
        deck.icon = type.icon
        deck.createdAt = Date()
        deck.updatedAt = Date()
        
        // Add cards based on deck type
        switch type {
        case .swiftFundamentals:
            addSwiftFundamentalsCards(to: deck, context: context)
        case .swiftUI:
            addSwiftUICards(to: deck, context: context)
        case .designPatterns:
            addDesignPatternsCards(to: deck, context: context)
        case .algorithms:
            addAlgorithmsCards(to: deck, context: context)
        case .systemDesign:
            addSystemDesignCards(to: deck, context: context)
        case .networking:
            addNetworkingCards(to: deck, context: context)
        case .testing:
            addTestingCards(to: deck, context: context)
        case .performance:
            addPerformanceCards(to: deck, context: context)
        }
        
        try? context.save()
    }
    
    private static func addSwiftFundamentalsCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "What are Swift's value types and reference types?",
                """
                **Value Types (Stack)**:
                - Structs, Enums, Tuples
                - Copy semantics
                - Thread safe by default
                - Preferred for data models
                
                **Reference Types (Heap)**:
                - Classes, Closures
                - Reference semantics
                - Shared state
                - Used for shared resources
                
                Example:
                ```swift
                struct Point { var x, y: Int } // Value type
                class Person { var name: String } // Reference type
                ```
                """
            ),
            (
                "Explain Swift's Optional type and its different forms",
                """
                **Optionals** represent values that may or may not exist.
                
                **Forms**:
                1. Regular Optional: `var name: String?`
                2. Implicitly Unwrapped: `var name: String!`
                
                **Unwrapping Methods**:
                ```swift
                // Optional binding
                if let name = optionalName {
                    print(name)
                }
                
                // Guard statement
                guard let name = optionalName else {
                    return
                }
                
                // Nil coalescing
                let name = optionalName ?? "Default"
                
                // Optional chaining
                let count = optionalString?.count
                ```
                """
            ),
            (
                "What are Swift protocols and protocol-oriented programming?",
                """
                **Protocols** define a blueprint of methods, properties, and requirements.
                
                **Key Concepts**:
                1. Protocol Inheritance
                2. Protocol Composition
                3. Protocol Extensions
                
                **Example**:
                ```swift
                protocol Drawable {
                    func draw()
                }
                
                extension Drawable {
                    func prepare() {
                        // Default implementation
                    }
                }
                
                struct Circle: Drawable {
                    func draw() {
                        // Implementation
                    }
                }
                ```
                
                **Benefits**:
                - Better abstraction
                - Code reuse
                - Composition over inheritance
                - Type safety
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addSwiftUICards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "Explain the SwiftUI View protocol and its lifecycle",
                """
                **View Protocol**
                The fundamental protocol for UI components in SwiftUI.
                
                **Key Requirements**:
                ```swift
                protocol View {
                    associatedtype Body: View
                    var body: Self.Body { get }
                }
                ```
                
                **View Lifecycle**:
                1. Initialization
                2. `body` property evaluation
                3. View update cycle
                4. Cleanup
                
                **State Management**:
                - `@State` for local state
                - `@Binding` for shared state
                - `@ObservedObject` for external objects
                - `@EnvironmentObject` for dependency injection
                """
            ),
            (
                "What are Property Wrappers in SwiftUI and how are they used?",
                """
                **Common Property Wrappers**:
                
                1. `@State`:
                ```swift
                @State private var count = 0
                ```
                - For local view state
                - Triggers view updates
                
                2. `@Binding`:
                ```swift
                struct ChildView {
                    @Binding var value: String
                }
                ```
                - Two-way connection
                
                3. `@ObservedObject`:
                ```swift
                class UserData: ObservableObject {
                    @Published var name = ""
                }
                ```
                - External state management
                
                4. `@EnvironmentObject`:
                ```swift
                @EnvironmentObject var settings: Settings
                ```
                - Dependency injection
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addDesignPatternsCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "Explain the Singleton pattern and its use cases in iOS",
                """
                **Singleton Pattern**
                
                **Definition**:
                Ensures a class has only one instance with global access point.
                
                **Implementation**:
                ```swift
                class NetworkManager {
                    static let shared = NetworkManager()
                    private init() {}
                    
                    func fetch() { }
                }
                ```
                
                **Use Cases**:
                - UserDefaults.standard
                - FileManager.default
                - URLSession.shared
                
                **Pros**:
                - Guaranteed single instance
                - Global access point
                
                **Cons**:
                - Can make testing difficult
                - Global state
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addAlgorithmsCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "Explain Big O Notation and its importance",
                """
                **Big O Notation**
                Describes algorithm efficiency as input size grows.
                
                **Common Complexities**:
                - O(1): Constant time
                - O(log n): Logarithmic
                - O(n): Linear
                - O(n log n): Linearithmic
                - O(n²): Quadratic
                
                **Example**:
                ```swift
                // O(1)
                func getFirst(_ array: [Int]) -> Int? {
                    return array.first
                }
                
                // O(n)
                func findElement(_ array: [Int], _ target: Int) -> Bool {
                    return array.contains(target)
                }
                
                // O(n²)
                func bubbleSort(_ array: [Int]) -> [Int] {
                    // Implementation
                }
                ```
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addSystemDesignCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "What is the MVVM architecture pattern?",
                """
                **MVVM (Model-View-ViewModel)**
                
                **Components**:
                1. **Model**: Data and business logic
                2. **View**: UI elements and layout
                3. **ViewModel**: View state and behavior
                
                **Example**:
                ```swift
                // Model
                struct User {
                    let name: String
                    let email: String
                }
                
                // ViewModel
                class UserViewModel: ObservableObject {
                    @Published var user: User?
                    
                    func fetchUser() {
                        // Fetch and update user
                    }
                }
                
                // View
                struct UserView: View {
                    @ObservedObject var viewModel: UserViewModel
                    
                    var body: some View {
                        // UI implementation
                    }
                }
                ```
                
                **Benefits**:
                - Separation of concerns
                - Testability
                - Reusability
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addNetworkingCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "Explain URLSession and its components",
                """
                **URLSession**
                Foundation framework for HTTP networking.
                
                **Components**:
                1. URLSession
                2. URLSessionConfiguration
                3. URLSessionTask
                
                **Example**:
                ```swift
                let session = URLSession.shared
                
                let task = session.dataTask(with: url) { data, response, error in
                    if let error = error {
                        print("Error: \\(error)")
                        return
                    }
                    
                    guard let data = data else { return }
                    // Handle data
                }
                
                task.resume()
                ```
                
                **Task Types**:
                - DataTask
                - DownloadTask
                - UploadTask
                - WebSocketTask
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addTestingCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "What is XCTest and how is it used for unit testing?",
                """
                **XCTest Framework**
                Apple's testing framework for iOS development.
                
                **Key Components**:
                1. XCTestCase
                2. Test Methods
                3. Assertions
                
                **Example**:
                ```swift
                class CalculatorTests: XCTestCase {
                    var calculator: Calculator!
                    
                    override func setUp() {
                        super.setUp()
                        calculator = Calculator()
                    }
                    
                    func testAddition() {
                        // Given
                        let a = 5
                        let b = 3
                        
                        // When
                        let result = calculator.add(a, b)
                        
                        // Then
                        XCTAssertEqual(result, 8)
                    }
                }
                ```
                
                **Best Practices**:
                - Follow AAA pattern (Arrange, Act, Assert)
                - Test edge cases
                - Keep tests independent
                - Use meaningful names
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addPerformanceCards(to deck: Deck, context: NSManagedObjectContext) {
        let cards: [(front: String, back: String)] = [
            (
                "What are the key aspects of iOS app performance optimization?",
                """
                **Performance Optimization Areas**
                
                1. **Memory Management**:
                - ARC (Automatic Reference Counting)
                - Memory leaks prevention
                - Cache management
                
                2. **UI Performance**:
                ```swift
                // Optimize table views
                class MyCell: UITableViewCell {
                    override func prepareForReuse() {
                        super.prepareForReuse()
                        // Clean up resources
                    }
                }
                ```
                
                3. **Network Optimization**:
                - Request caching
                - Data compression
                - Background transfers
                
                4. **Image Handling**:
                - Proper image scaling
                - Caching
                - Progressive loading
                
                5. **Instruments Usage**:
                - Time Profiler
                - Allocations
                - Leaks
                """
            ),
            // Add more cards...
        ]
        
        addCards(cards, to: deck, context: context)
    }
    
    private static func addCards(_ cards: [(front: String, back: String)], to deck: Deck, context: NSManagedObjectContext) {
        for (index, cardContent) in cards.enumerated() {
            let card = Card(context: context)
            card.id = UUID()
            card.front = cardContent.front
            card.back = cardContent.back
            card.deck = deck
            card.createdAt = Date()
            card.updatedAt = Date()
            card.order = Int16(index)
            card.dueDate = Date()
        }
    }
} 