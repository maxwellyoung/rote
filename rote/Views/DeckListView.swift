import SwiftUI

struct DeckListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Deck.createdAt, ascending: false)],
        animation: .default
    )
    private var decks: FetchedResults<Deck>
    
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @State private var showingNewDeckSheet = false
    @State private var showingBuiltInDecks = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(decks) { deck in
                    NavigationLink(destination: DeckDetailView(deck: deck)) {
                        DeckRow(deck: deck)
                    }
                    .listRowBackground(Color.hex("1C1C1E"))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: deleteDeck)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search decks")
            .navigationTitle("Decks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingBuiltInDecks = true }) {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundColor(Color.hex(accentColor))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewDeckSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.hex(accentColor))
                    }
                }
            }
            .sheet(isPresented: $showingNewDeckSheet) {
                NewDeckView()
            }
            .sheet(isPresented: $showingBuiltInDecks) {
                BuiltInDecksView()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func deleteDeck(at offsets: IndexSet) {
        withAnimation {
            offsets.map { decks[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct DeckRow: View {
    let deck: Deck
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(deck.title ?? "Untitled Deck")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(deck.cards?.count ?? 0) cards")
                    .font(.system(size: 15))
                    .foregroundColor(Color.hex("8E8E93"))
            }
            
            if let type = deck.type {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(Color.hex(accentColor))
                        .font(.system(size: 12))
                    Text(type)
                        .font(.system(size: 15))
                        .foregroundColor(Color.hex("8E8E93"))
                }
            }
            
            if let topic = deck.topic {
                Text(topic)
                    .font(.system(size: 15))
                    .foregroundColor(Color.hex("8E8E93"))
            }
        }
        .padding(.vertical, 12)
    }
}

struct NewDeckView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var type = ""
    @State private var topic = ""
    
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
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createDeck()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func createDeck() {
        withAnimation {
            let deck = Deck(context: viewContext)
            deck.id = UUID()
            deck.title = title
            deck.type = type.isEmpty ? nil : type
            deck.topic = topic.isEmpty ? nil : topic
            deck.createdAt = Date()
            
            try? viewContext.save()
            dismiss()
        }
    }
} 