import SwiftUI

struct EditCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var card: Card
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    @State private var front: String
    @State private var back: String
    @State private var showingPreview = false
    @State private var tags: [String]
    @State private var newTag = ""
    
    init(card: Card) {
        self.card = card
        _front = State(initialValue: card.front ?? "")
        _back = State(initialValue: card.back ?? "")
        _tags = State(initialValue: card.tags)
    }
    
    var body: some View {
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
            
            Section(header: Text("Tags").foregroundColor(.gray)) {
                ForEach(tags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { removeTag(tag) }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onDelete(perform: deleteTags)
                
                HStack {
                    TextField("Add tag...", text: $newTag)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !newTag.isEmpty {
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color.hex(accentColor))
                        }
                    }
                }
            }
            .listRowBackground(Color.hex("1C1C1E"))
        }
        .navigationTitle("Edit Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    updateCard()
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
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return }
        
        withAnimation {
            tags.append(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
    
    private func deleteTags(at offsets: IndexSet) {
        withAnimation {
            tags.remove(atOffsets: offsets)
        }
    }
    
    private func updateCard() {
        withAnimation {
            card.front = front
            card.back = back.isEmpty ? nil : back
            card.tags = tags
            
            try? viewContext.save()
            dismiss()
        }
    }
} 