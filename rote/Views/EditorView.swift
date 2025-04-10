import SwiftUI

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = CardViewModel()
    @State private var showingTags = false
    @State private var newTag = ""
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Front")) {
                    TextEditor(text: $viewModel.front)
                        .frame(minHeight: 100)
                        .font(.system(.body, design: .rounded))
                }
                
                Section(header: Text("Back")) {
                    TextEditor(text: $viewModel.back)
                        .frame(minHeight: 100)
                        .font(.system(.body, design: .rounded))
                }
                
                Section(header: Text("Tags")) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        Text(tag)
                    }
                    .onDelete { indices in
                        viewModel.tags.remove(atOffsets: indices)
                    }
                    
                    Button(action: { showingTags = true }) {
                        Label("Add Tag", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCard()
                        // Switch to Review tab after saving
                        selectedTab = 0
                    }
                    .disabled(!viewModel.isValid)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.reset()
                        // Switch to Review tab
                        selectedTab = 0
                    }
                }
            }
            .sheet(isPresented: $showingTags) {
                tagSheet
            }
        }
    }
    
    private var tagSheet: some View {
        NavigationView {
            Form {
                TextField("New Tag", text: $newTag)
                    .autocapitalization(.none)
                
                Button("Add") {
                    if !newTag.isEmpty {
                        viewModel.tags.append(newTag)
                        newTag = ""
                        showingTags = false
                    }
                }
                .disabled(newTag.isEmpty)
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingTags = false
                    }
                }
            }
        }
    }
    
    private func saveCard() {
        let newCard = Card(context: viewContext)
        newCard.id = UUID()
        newCard.front = viewModel.front
        newCard.back = viewModel.back
        newCard.tags = viewModel.tags
        newCard.interval = 1.0
        newCard.ease = 2.5
        newCard.dueDate = Date()
        newCard.createdAt = Date()
        newCard.modifiedAt = Date()
        
        do {
            try viewContext.save()
            viewModel.reset()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(selectedTab: .constant(0))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 