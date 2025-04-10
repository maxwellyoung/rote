import SwiftUI
import CoreData

struct ReviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        predicate: NSPredicate(format: "dueDate <= %@", Date() as NSDate),
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    @State private var showingAnswer = false
    @State private var isRotating = false
    
    // Haptic feedback generators
    private let impactMed = UIImpactFeedbackGenerator(style: .medium)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1A1A1A"), Color(hex: "0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                if let card = cards.first {
                    VStack {
                        // Progress indicator
                        ProgressView(value: Double(cards.count), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "5E5CE6")))
                            .frame(maxWidth: .infinity, maxHeight: 2)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        
                        Spacer()
                        
                        CardView(card: card, showingAnswer: $showingAnswer, isRotating: $isRotating)
                            .offset(x: offset.width, y: offset.height)
                            .rotation3DEffect(
                                .degrees(isRotating ? 180 : 0),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        offset = gesture.translation
                                        withAnimation {
                                            color = getColorForGesture(offset)
                                        }
                                        if abs(offset.width).truncatingRemainder(dividingBy: 50) < 1 ||
                                           abs(offset.height).truncatingRemainder(dividingBy: 50) < 1 {
                                            impactLight.impactOccurred()
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                            handleSwipe(offset)
                                        }
                                    }
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: offset)
                        
                        Spacer()
                        
                        // Gesture hints
                        GestureHintsView()
                            .padding(.bottom, 30)
                    }
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Color(hex: "5E5CE6"))
                    }
                }
            }
        }
    }
    
    private func getColorForGesture(_ gesture: CGSize) -> Color {
        if abs(gesture.height) > abs(gesture.width) && gesture.height < 0 {
            // Swiping up - Easy
            let normalizedHeight = min(abs(gesture.height) / UIScreen.main.bounds.height, 0.8)
            return .blue.opacity(normalizedHeight)
        } else {
            // Swiping horizontally
            let normalizedWidth = abs(gesture.width) / UIScreen.main.bounds.width
            if gesture.width > 0 {
                return .green.opacity(min(normalizedWidth, 0.8))
            } else {
                return .red.opacity(min(normalizedWidth, 0.8))
            }
        }
    }
    
    private func handleSwipe(_ gesture: CGSize) {
        let card = cards.first!
        
        // Determine the primary direction of the swipe
        if abs(gesture.height) > abs(gesture.width) && gesture.height < -100 {
            // Swipe up - Easy
            impactMed.impactOccurred()
            updateCard(card, rating: .easy)
            offset = CGSize(width: 0, height: -500)
        } else {
            switch gesture.width {
            case -500...(-150):
                // Swipe left - Again
                impactMed.impactOccurred()
                updateCard(card, rating: .again)
                offset = CGSize(width: -500, height: 0)
            case 150...500:
                // Swipe right - Good
                impactMed.impactOccurred()
                updateCard(card, rating: .good)
                offset = CGSize(width: 500, height: 0)
            default:
                offset = .zero
            }
        }
        
        // Reset position after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            offset = .zero
            showingAnswer = false
        }
    }
    
    private func updateCard(_ card: Card, rating: ReviewRating) {
        let (newInterval, newEase) = calculateNextReview(card: card, rating: rating)
        
        // Update card properties
        card.interval = newInterval
        card.ease = newEase
        card.dueDate = Date().addingTimeInterval(newInterval * 86400) // Convert days to seconds
        card.lastReviewDate = Date()
        card.reviewCount += 1
        
        // Create new review record
        let review = Review(context: viewContext)
        review.date = Date()
        review.rating = rating.rawValue
        review.ease = newEase
        review.interval = newInterval
        review.card = card
        
        // Update streak
        let calendar = Calendar.current
        if let lastReview = card.lastReviewDate,
           calendar.isDateInToday(lastReview) || calendar.isDateInYesterday(lastReview) {
            card.streak += 1
        } else {
            card.streak = 1
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func calculateNextReview(card: Card, rating: ReviewRating) -> (interval: Double, ease: Double) {
        // Implementation of the SM-2 algorithm
        var ease = card.ease
        var interval = card.interval
        
        switch rating {
        case .again:
            // Failed recall, reset interval and reduce ease
            ease = max(1.3, ease - 0.2)
            interval = 1.0
            
        case .good:
            if interval <= 1.0 {
                // First successful recall
                interval = 4.0
            } else {
                // Regular review, increase interval
                interval *= ease
            }
            // Small ease adjustment
            ease = max(1.3, ease - 0.08)
            
        case .easy:
            if interval <= 1.0 {
                // First successful recall with high confidence
                interval = 7.0
            } else {
                // Easy review, increase interval more
                interval *= (ease * 1.3)
            }
            // Increase ease
            ease = min(2.5, ease + 0.15)
        }
        
        // Ensure minimum interval of 1 day
        interval = max(1.0, interval)
        
        return (interval, ease)
    }
}

enum ReviewRating: String {
    case again = "again"
    case good = "good"
    case easy = "easy"
}

struct CardView: View {
    let card: Card
    @Binding var showingAnswer: Bool
    @Binding var isRotating: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1C1C1E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 24) {
                    Text(showingAnswer ? (card.back ?? "") : (card.front ?? ""))
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                    
                    if let tags = card.tags {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: "5E5CE6"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "5E5CE6").opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .frame(height: 400)
            .padding(.horizontal, 20)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isRotating.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showingAnswer.toggle()
                    }
                }
            }
        }
    }
}

struct GestureHintsView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 40) {
                GestureHint(icon: "arrow.left", text: "Again", color: Color(hex: "FF3B30"))
                GestureHint(icon: "arrow.right", text: "Good", color: Color(hex: "34C759"))
            }
            
            GestureHint(icon: "arrow.up", text: "Easy", color: Color(hex: "5E5CE6"))
        }
        .padding(.horizontal, 40)
    }
}

struct GestureHint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "8E8E93"))
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "34C759"))
            
            VStack(spacing: 8) {
                Text("All caught up!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Come back later for more cards")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: true)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ReviewView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 