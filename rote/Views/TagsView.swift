import SwiftUI
import CoreData

struct TagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest<Card>(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)],
        animation: .default
    ) private var cards: FetchedResults<Card>
    
    @State private var searchText = ""
    @State private var showingRenameSheet = false
    @State private var selectedTag: String?
    @State private var newTagName = ""
    @State private var isEditMode = false
    @State private var selectedTags = Set<String>()
    @State private var showingBatchActionSheet = false
    @State private var showingMergeSheet = false
    @State private var mergeTargetTag: String?
    @State private var showingColorSheet = false
    @AppStorage("tagColors") private var tagColorsData = "{}"
    
    private var tagColors: [String: String] {
        get {
            if let data = tagColorsData.data(using: .utf8),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                return dict
            }
            return [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                tagColorsData = string
            }
        }
    }
    
    private mutating func updateTagColor(_ tag: String, color: String) {
        var colors = tagColors
        colors[tag] = color
        tagColors = colors
    }
    
    var filteredTags: [String] {
        let allTags = Array(Set(cards.compactMap { $0.tags }.flatMap { $0 }))
        if searchText.isEmpty {
            return allTags.sorted()
        }
        return allTags.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
    }
    
    private var tagGroups: [String: [Card]] {
        let allCards = cards.compactMap { $0 }
        var groups: [String: [Card]] = [:]
        
        for card in allCards {
            for tag in card.tags {
                groups[tag, default: []].append(card)
            }
        }
        
        return groups
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            if filteredTags.isEmpty {
                EmptyStateView(
                    icon: "tag.slash",
                    title: "No tags found",
                    message: "Add tags to your cards to organize them"
                )
            } else {
                TagListView(
                    searchText: searchText,
                    filteredTags: filteredTags,
                    tagGroups: tagGroups,
                    tagColorsData: tagColorsData,
                    isEditMode: $isEditMode,
                    selectedTags: $selectedTags,
                    onDeleteTag: deleteTag,
                    onRenameTag: { tag in
                        selectedTag = tag
                        newTagName = tag
                        showingRenameSheet = true
                    },
                    onColorTag: { tag in
                        selectedTag = tag
                        showingColorSheet = true
                    }
                )
            }
        }
        .navigationTitle("Tags")
        .sheet(isPresented: $showingRenameSheet) {
            if let tag = selectedTag {
                RenameTagView(
                    tag: tag,
                    newName: $newTagName,
                    onRename: { renameTag(from: tag, to: $0) }
                )
            }
        }
        .sheet(isPresented: $showingColorSheet) {
            if let tag = selectedTag {
                TagColorPickerView(
                    tag: tag,
                    selectedColor: tagColors[tag] ?? "5E5CE6",
                    onColorSelected: { color in
                        withAnimation {
                            $tagColorsData.wrappedValue = try! JSONEncoder()
                                .encode(tagColors.merging([tag: color]) { $1 })
                                .toString()
                        }
                    }
                )
            }
        }
    }
    
    private func deleteTag(_ tag: String) {
        withAnimation {
            for card in cards {
                var cardTags = card.tags
                cardTags.removeAll { $0 == tag }
                card.tags = cardTags
            }
            try? viewContext.save()
        }
    }
    
    private func deleteTags(_ tags: [String]) {
        withAnimation {
            for card in cards {
                var cardTags = card.tags
                cardTags.removeAll { tags.contains($0) }
                card.tags = cardTags
            }
            selectedTags.removeAll()
            try? viewContext.save()
        }
    }
    
    private func mergeTags(into targetTag: String) {
        withAnimation {
            for card in cards {
                var cardTags = card.tags
                if cardTags.contains(where: { selectedTags.contains($0) }) {
                    cardTags.removeAll { selectedTags.contains($0) }
                    if !cardTags.contains(targetTag) {
                        cardTags.append(targetTag)
                    }
                    card.tags = cardTags
                }
            }
            selectedTags.removeAll()
            try? viewContext.save()
        }
    }
    
    private func renameTag(from oldTag: String, to newTag: String) {
        withAnimation {
            for card in cards {
                var cardTags = card.tags
                if let index = cardTags.firstIndex(of: oldTag) {
                    cardTags[index] = newTag
                    card.tags = cardTags
                }
            }
            try? viewContext.save()
            showingRenameSheet = false
        }
    }
}

// MARK: - Tag List View
private struct TagListView: View {
    let searchText: String
    let filteredTags: [String]
    let tagGroups: [String: [Card]]
    let tagColorsData: String
    @Binding var isEditMode: Bool
    @Binding var selectedTags: Set<String>
    let onDeleteTag: (String) -> Void
    let onRenameTag: (String) -> Void
    let onColorTag: (String) -> Void
    
    private var tagColors: [String: String] {
        if let data = tagColorsData.data(using: .utf8),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            return dict
        }
        return [:]
    }
    
    var body: some View {
        List {
            ForEach(filteredTags, id: \.self) { tag in
                NavigationLink(destination: TagDetailView(tag: tag)) {
                    HStack {
                        Circle()
                            .fill(Color.hex(tagColors[tag] ?? "5E5CE6"))
                            .frame(width: 12, height: 12)
                        Text(tag)
                        Spacer()
                        Text("\(tagGroups[tag]?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDeleteTag(tag)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        onRenameTag(tag)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(.yellow)
                    
                    Button {
                        onColorTag(tag)
                    } label: {
                        Label("Color", systemImage: "paintpalette")
                    }
                    .tint(.orange)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Tag Row
private struct TagRow: View {
    let tag: String
    let cardCount: Int
    let color: String
    
    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .foregroundColor(Color.hex(color))
                .font(.system(size: 14))
            
            Text(tag)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(cardCount)")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Search Bar
private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search tags...", text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color.hex("2C2C2E"))
        .cornerRadius(8)
    }
}

// MARK: - Tag Detail View
struct TagDetailView: View {
    let tag: String
    @AppStorage("tagColors") private var tagColorsData = "{}"
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest<Card> private var cards: FetchedResults<Card>
    @State private var selectedCard: Card?
    @State private var showingEditSheet = false
    
    private var tagColors: [String: String] {
        get {
            if let data = tagColorsData.data(using: .utf8),
               let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                return dict
            }
            return [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                tagColorsData = string
            }
        }
    }
    
    init(tag: String) {
        self.tag = tag
        let predicate = NSPredicate(format: "ANY tags CONTAINS[c] %@", tag)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)]
        _cards = FetchRequest<Card>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
    }
    
    private var tagColor: String {
        tagColors[tag] ?? accentColor
    }
    
    var body: some View {
        List {
            ForEach(cards) { card in
                CardRow(card: card)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation {
                                var cardTags = card.tags
                                cardTags.removeAll { $0 == tag }
                                card.tags = cardTags
                                try? viewContext.save()
                            }
                        } label: {
                            Label("Remove Tag", systemImage: "tag.slash")
                        }
                        
                        Button {
                            selectedCard = card
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.yellow)
                    }
            }
        }
        .listStyle(.plain)
        .navigationTitle(tag)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            if let card = selectedCard {
                EditCardView(card: card)
            }
        }
    }
}

// MARK: - Rename Tag View
private struct RenameTagView: View {
    let tag: String
    @Binding var newName: String
    let onRename: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    var body: some View {
        Form {
            Section {
                TextField("Tag name", text: $newName)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .listRowBackground(Color.hex("1C1C1E"))
        }
        .navigationTitle("Rename Tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onRename(newName)
                    dismiss()
                }
                .disabled(newName.isEmpty || newName == tag)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Merge Tags View
private struct MergeTagsView: View {
    let selectedTags: [String]
    let allTags: [String]
    let onMerge: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @State private var searchText = ""
    @State private var targetTag: String?
    
    private var availableTags: [String] {
        allTags.filter { !selectedTags.contains($0) }
    }
    
    private var filteredTags: [String] {
        if searchText.isEmpty {
            return availableTags
        }
        return availableTags.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(selectedTags, id: \.self) { tag in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color.hex(accentColor))
                        Text(tag)
                            .foregroundColor(.white)
                    }
                }
            } header: {
                Text("Selected Tags")
                    .foregroundColor(.gray)
            }
            .listRowBackground(Color.hex("1C1C1E"))
            
            Section {
                ForEach(filteredTags, id: \.self) { tag in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color.hex(accentColor))
                        Text(tag)
                            .foregroundColor(.white)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        targetTag = tag
                    }
                    .overlay(alignment: .trailing) {
                        if targetTag == tag {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.hex(accentColor))
                        }
                    }
                }
            } header: {
                Text("Merge Into")
                    .foregroundColor(.gray)
            }
            .listRowBackground(Color.hex("1C1C1E"))
        }
        .searchable(text: $searchText, prompt: "Search tags...")
        .navigationTitle("Merge Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Merge") {
                    if let targetTag = targetTag {
                        onMerge(targetTag)
                        dismiss()
                    }
                }
                .disabled(targetTag == nil)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Tag Color Picker View
private struct TagColorPickerView: View {
    let tag: String
    @State private var selectedColor: String
    let onColorSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let colors = [
        "5E5CE6", // Blue
        "FF3B30", // Red
        "34C759", // Green
        "FF9500", // Orange
        "FF2D55", // Pink
        "5856D6", // Purple
        "FFCC00", // Yellow
        "00C7BE", // Teal
        "FF6482", // Rose
        "32ADE6", // Sky
    ]
    
    init(tag: String, selectedColor: String, onColorSelected: @escaping (String) -> Void) {
        self.tag = tag
        self._selectedColor = State(initialValue: selectedColor)
        self.onColorSelected = onColorSelected
    }
    
    var body: some View {
        List {
            Section {
                TagRow(
                    tag: tag,
                    cardCount: 0,
                    color: selectedColor
                )
                .listRowBackground(Color.hex("1C1C1E"))
            } header: {
                Text("Preview")
                    .foregroundColor(.gray)
            }
            
            Section {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 44))
                ], spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Circle()
                            .fill(Color.hex(color))
                            .frame(width: 44, height: 44)
                            .overlay {
                                if color == selectedColor {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }
                            .onTapGesture {
                                selectedColor = color
                                onColorSelected(color)
                            }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Colors")
                    .foregroundColor(.gray)
            }
            .listRowBackground(Color.hex("1C1C1E"))
        }
        .navigationTitle("Tag Color")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Array Extension
private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

struct TagsView_Previews: PreviewProvider {
    static var previews: some View {
        TagsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}

private extension Data {
    func toString() -> String {
        String(data: self, encoding: .utf8) ?? "{}"
    }
} 