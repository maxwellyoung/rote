import SwiftUI
import CoreData

struct DeckDetailView: View {
    @ObservedObject var deck: Deck
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    @State private var showingNewCardSheet = false
    @State private var showingEditSheet = false
    @State private var searchText = ""
    
    private var cards: [Card] {
        let allCards = deck.cards?.allObjects as? [Card] ?? []
        if searchText.isEmpty {
            return allCards.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        } else {
            return allCards.filter { card in
                let front = card.front?.lowercased() ?? ""
                let back = card.back?.lowercased() ?? ""
                let search = searchText.lowercased()
                return front.contains(search) || back.contains(search)
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if let type = deck.type {
                            Text(type)
                                .font(.system(size: 15))
                                .foregroundColor(Color.hex(accentColor))
                        }
                        Spacer()
                        Text("\(cards.count) cards")
                            .font(.system(size: 15))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    
                    if let topic = deck.topic {
                        Text(topic)
                            .font(.system(size: 14))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: { showingNewCardSheet = true }) {
                            Label("Add Card", systemImage: "plus")
                                .foregroundColor(Color.hex(accentColor))
                        }
                        Spacer()
                        Button(action: { showingEditSheet = true }) {
                            Label("Edit Deck", systemImage: "pencil")
                                .foregroundColor(Color.hex(accentColor))
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.hex("1C1C1E"))
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            
            ForEach(cards) { card in
                CardRow(card: card)
                    .listRowBackground(Color.hex("1C1C1E"))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteCards)
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search cards")
        .navigationTitle(deck.title ?? "Untitled Deck")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewCardSheet) {
            NewCardView(deck: deck)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDeckView(deck: deck)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func deleteCards(at offsets: IndexSet) {
        withAnimation {
            offsets.map { cards[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct EditDeckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var deck: Deck
    
    @State private var title: String
    @State private var type: String
    @State private var topic: String
    
    init(deck: Deck) {
        self.deck = deck
        _title = State(initialValue: deck.title ?? "")
        _type = State(initialValue: deck.type ?? "")
        _topic = State(initialValue: deck.topic ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .foregroundColor(.white)
                    TextField("Type (e.g. DSA, Language)", text: $type)
                        .foregroundColor(.white)
                    TextField("Topic (e.g. Arrays, Grammar)", text: $topic)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.hex("1C1C1E"))
            }
            .navigationTitle("Edit Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateDeck()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func updateDeck() {
        withAnimation {
            deck.title = title
            deck.type = type.isEmpty ? nil : type
            deck.topic = topic.isEmpty ? nil : topic
            
            try? viewContext.save()
            dismiss()
        }
    }
}

struct NewCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var deck: Deck
    
    @State private var front = ""
    @State private var back = ""
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Front").foregroundColor(.gray)) {
                    if showingPreview {
                        MarkdownText(text: front)
                            .foregroundColor(.white)
                    } else {
                        TextEditor(text: $front)
                            .frame(minHeight: 100)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.hex("1C1C1E"))
                
                Section(header: Text("Back").foregroundColor(.gray)) {
                    if showingPreview {
                        MarkdownText(text: back)
                            .foregroundColor(.white)
                    } else {
                        TextEditor(text: $back)
                            .frame(minHeight: 100)
                            .foregroundColor(.white)
                    }
                }
                .listRowBackground(Color.hex("1C1C1E"))
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCard()
                    }
                    .disabled(front.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showingPreview ? "Edit" : "Preview") {
                        showingPreview.toggle()
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func createCard() {
        withAnimation {
            let card = Card(context: viewContext)
            card.id = UUID()
            card.front = front
            card.back = back
            card.createdAt = Date()
            card.deck = deck
            
            try? viewContext.save()
            dismiss()
        }
    }
} 