import SwiftUI
import CoreData

struct StudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default
    ) private var cards: FetchedResults<Card>
    @State private var currentIndex = 0
    @State private var showingAnswer = false
    @State private var showingStats = false
    @State private var showingSettings = false
    @State private var showingDeckPicker = false
    @State private var selectedDeck: Deck?
    @State private var isShuffled = false
    @State private var studyAllDecks = false
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    private var filteredCards: [Card] {
        let allCards = Array(self.cards).filter { $0.isReadyForReview }
        
        if studyAllDecks {
            return isShuffled ? allCards.shuffled() : allCards.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        }
        
        if let selectedDeck = selectedDeck {
            let deckCards = allCards.filter { $0.deck == selectedDeck }
            return isShuffled ? deckCards.shuffled() : deckCards.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        }
        
        return []
    }
    
    private var currentCard: Card? {
        guard !filteredCards.isEmpty else { return nil }
        return filteredCards[currentIndex]
    }
    
    private var progress: Double {
        guard !filteredCards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(filteredCards.count)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                deckPickerButton
            }
            ToolbarItem(placement: .principal) {
                deckIndicator
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                menuButton
            }
        }
        .sheet(isPresented: $showingDeckPicker) {
            deckPickerSheet
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var navigationTitle: String {
        if filteredCards.isEmpty {
            return "Study"
        }
        if studyAllDecks {
            return "Study All"
        }
        return selectedDeck?.title ?? "Study"
    }
    
    private var deckIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.stack.fill")
                .foregroundColor(Color.hex(accentColor))
            Text(studyAllDecks ? "All Decks" : (selectedDeck?.title ?? "Select Deck"))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
        .onTapGesture {
            showingDeckPicker = true
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if !filteredCards.isEmpty {
                progressBar
                Spacer()
                cardContent
                Spacer()
                answerControls
            } else {
                WelcomeView(
                    studyAllDecks: $studyAllDecks,
                    showingDeckPicker: $showingDeckPicker
                )
            }
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.hex("2C2C2E"))
                Rectangle()
                    .fill(Color.hex(accentColor))
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 2)
    }
    
    private var cardContent: some View {
        Group {
            if let card = currentCard {
                CardView(card: card, showingAnswer: $showingAnswer)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
            } else {
                // Fallback empty state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(Color.hex("8E8E93"))
                    Text("All caught up!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text("No more cards to review")
                        .font(.system(size: 15))
                        .foregroundColor(Color.hex("8E8E93"))
                }
                .transition(.opacity)
            }
        }
    }
    
    private var answerControls: some View {
        Group {
            if let card = currentCard {
                if showingAnswer {
                    RatingButtons(card: card) { grade in
                        print("Rating selected: \(grade)")
                        do {
                            card.scheduleReview(grade: grade)
                            try viewContext.save()
                            print("Successfully saved review")
                            withAnimation(.easeInOut(duration: 0.3)) {
                                nextCard()
                            }
                        } catch {
                            print("Error saving review: \(error)")
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                } else {
                    showAnswerButton
                }
            }
        }
    }
    
    private var showAnswerButton: some View {
        Button(action: {
            print("Show answer button tapped")
            guard currentCard != nil else {
                print("Warning: Attempted to show answer with no current card")
                return
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAnswer = true
            }
            print("Show answer animation started")
        }) {
            Text("Show Answer")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.hex(accentColor))
                .cornerRadius(10)
        }
        .padding()
        .disabled(currentCard == nil)
        .opacity(currentCard == nil ? 0.5 : 1.0)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    private var deckPickerButton: some View {
        Button(action: { showingDeckPicker = true }) {
            Image(systemName: "rectangle.stack")
                .foregroundColor(.white)
        }
    }
    
    private var menuButton: some View {
        Menu {
            Toggle("Shuffle Cards", isOn: $isShuffled)
            Toggle("Study All Decks", isOn: $studyAllDecks)
            Button(action: { showingStats = true }) {
                Label("Stats", systemImage: "chart.bar")
            }
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.white)
        }
    }
    
    private var deckPickerSheet: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Cover Flow carousel
                    GeometryReader { geometry in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: -20) {
                                // All Decks Cover
                                DeckCover(
                                    title: "All Decks",
                                    subtitle: "\(cards.count) cards total",
                                    iconName: "rectangle.stack.fill",
                                    isSelected: studyAllDecks,
                                    width: geometry.size.width * 0.8
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        studyAllDecks = true
                                        selectedDeck = nil
                                        showingDeckPicker = false
                                    }
                                }
                                
                                // Individual Deck Covers
                                ForEach(Array(cards.compactMap { $0.deck }.uniqued()), id: \.self) { deck in
                                    DeckCover(
                                        title: deck.title ?? "Untitled Deck",
                                        subtitle: "\(deck.cards?.count ?? 0) cards",
                                        iconName: "rectangle.on.rectangle",
                                        isSelected: selectedDeck == deck,
                                        width: geometry.size.width * 0.8
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            selectedDeck = deck
                                            studyAllDecks = false
                                            showingDeckPicker = false
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, geometry.size.width * 0.1)
                            .frame(height: geometry.size.height)
                        }
                    }
                    .frame(height: 400)
                    
                    // Selected deck info
                    VStack(spacing: 8) {
                        Text(studyAllDecks ? "All Decks" : (selectedDeck?.title ?? "Select a Deck"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(studyAllDecks ? "\(cards.count) cards total" : "\(selectedDeck?.cards?.count ?? 0) cards")
                            .font(.system(size: 17))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Select Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDeckPicker = false
                    }
                }
            }
        }
    }
    
    private struct DeckCover: View {
        let title: String
        let subtitle: String
        let iconName: String
        let isSelected: Bool
        let width: CGFloat
        @AppStorage("accentColor") private var accentColor = "5E5CE6"
        
        var body: some View {
            VStack {
                // Cover art
                ZStack {
                    // Reflection effect
                    VStack(spacing: 0) {
                        // Main card
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.hex("1C1C1E"))
                            .frame(width: width, height: width * 1.3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        // Reflection
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.hex("1C1C1E"))
                            .frame(width: width, height: width * 1.3)
                            .scaleEffect(x: 1, y: -0.25, anchor: .top)
                            .opacity(0.3)
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .white.opacity(0.1)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    // Content
                    VStack(spacing: 24) {
                        Image(systemName: iconName)
                            .font(.system(size: 64))
                            .foregroundColor(Color.hex(accentColor))
                        
                        VStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text(subtitle)
                                .font(.system(size: 17))
                                .foregroundColor(Color.hex("8E8E93"))
                        }
                    }
                    .padding(.vertical, 40)
                }
                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
            }
            .frame(width: width)
            .rotation3DEffect(
                .degrees(isSelected ? 0 : 70),
                axis: (x: 0, y: 1, z: 0),
                anchor: isSelected ? .center : .leading,
                perspective: 0.5
            )
            .scaleEffect(isSelected ? 1 : 0.8)
            .offset(x: isSelected ? 0 : -width * 0.3)
            .zIndex(isSelected ? 1 : 0)
        }
    }
    
    private func nextCard() {
        print("Moving to next card. Current index: \(currentIndex), Total cards: \(filteredCards.count)")
        showingAnswer = false
        
        if currentIndex < filteredCards.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
        print("New index: \(currentIndex)")
    }
    
    private struct WelcomeView: View {
        @Binding var studyAllDecks: Bool
        @Binding var showingDeckPicker: Bool
        @AppStorage("accentColor") private var accentColor = "5E5CE6"
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                // Icon and Title
                VStack(spacing: 24) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 64))
                        .foregroundColor(Color.hex("8E8E93"))
                    
                    Text("Welcome to Rote")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Description
                Text("Choose how you'd like to study")
                    .font(.system(size: 17))
                    .foregroundColor(Color.hex("8E8E93"))
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Study All Button
                    Button(action: {
                        withAnimation(.spring()) {
                            studyAllDecks = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Study All Decks")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Review cards from all your decks")
                                    .font(.system(size: 13))
                                    .opacity(0.8)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    // Choose Deck Button
                    Button(action: { showingDeckPicker = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Choose a Deck")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Select a specific deck to study")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.hex("2C2C2E"))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Array Extension
private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 