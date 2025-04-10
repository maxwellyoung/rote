import SwiftUI

struct TagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var selectedTag: String? = nil
    
    private var allTags: [String] {
        Array(Set(cards.flatMap { $0.tags ?? [] })).sorted()
    }
    
    var body: some View {
        NavigationView {
            List {
                if allTags.isEmpty {
                    Text("No tags yet")
                        .foregroundColor(.gray)
                } else {
                    ForEach(allTags, id: \.self) { tag in
                        NavigationLink(
                            destination: TaggedCardsView(tag: tag),
                            tag: tag,
                            selection: $selectedTag
                        ) {
                            HStack {
                                Text(tag)
                                Spacer()
                                Text("\(cards.filter { ($0.tags ?? []).contains(tag) }.count)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TaggedCardsView: View {
    let tag: String
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var taggedCards: FetchedResults<Card>
    
    init(tag: String) {
        self.tag = tag
        _taggedCards = FetchRequest<Card>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
            predicate: NSPredicate(format: "ANY tags == %@", tag),
            animation: .default
        )
    }
    
    var body: some View {
        List {
            ForEach(taggedCards) { card in
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.front ?? "")
                        .font(.headline)
                    Text(card.back ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Due: \(card.dueDate ?? Date(), formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(tag)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 