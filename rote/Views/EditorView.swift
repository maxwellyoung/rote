import SwiftUI
import CoreData

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = CardViewModel()
    @State private var showingTags = false
    @State private var newTag = ""
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 24) {
                    // Front card
                    EditorCardView(
                        title: "Front",
                        text: $viewModel.front,
                        placeholder: "Enter the question or prompt"
                    )
                    
                    // Back card
                    EditorCardView(
                        title: "Back",
                        text: $viewModel.back,
                        placeholder: "Enter the answer"
                    )
                    
                    // Tags section
                    tagsSection
                }
                .padding(16)
            }
        }
        .navigationTitle("New Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                cancelButton
            }
        }
        .sheet(isPresented: $showingTags) {
            tagSheet
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
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            if viewModel.tags.isEmpty {
                Text("No tags added yet")
                    .font(.system(size: 15))
                    .foregroundColor(Color.hex("8E8E93"))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                if let index = viewModel.tags.firstIndex(of: tag) {
                                    viewModel.tags.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
            
            addTagButton
        }
        .padding(16)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.hex("2C2C2E"), lineWidth: 1)
        )
    }
    
    private var addTagButton: some View {
        Button(action: { showingTags = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color.hex("5E5CE6"))
                Text("Add Tag")
                    .foregroundColor(Color.hex("5E5CE6"))
            }
            .font(.system(size: 17, weight: .medium))
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            saveCard()
            selectedTab = 0
        }) {
            Text("Save")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(viewModel.isValid ? Color.hex("5E5CE6") : Color.hex("8E8E93"))
        }
        .disabled(!viewModel.isValid)
    }
    
    private var cancelButton: some View {
        Button(action: {
            viewModel.reset()
            selectedTab = 0
        }) {
            Text("Cancel")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color.hex("8E8E93"))
        }
    }
    
    private var tagSheet: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 16) {
                    tagTextField
                    addNewTagButton
                }
                .padding(16)
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingTags = false
                    }
                    .foregroundColor(Color.hex("5E5CE6"))
                }
            }
        }
    }
    
    private var tagTextField: some View {
        TextField("", text: $newTag)
            .placeholder(when: newTag.isEmpty) {
                Text("Enter tag name")
                    .foregroundColor(Color.hex("8E8E93"))
            }
            .font(.system(size: 17))
            .foregroundColor(.white)
            .padding(16)
            .background(Color.hex("1C1C1E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.hex("2C2C2E"), lineWidth: 1)
            )
            .autocapitalization(.none)
    }
    
    private var addNewTagButton: some View {
        Button(action: {
            if !newTag.isEmpty {
                viewModel.tags.append(newTag)
                newTag = ""
                showingTags = false
            }
        }) {
            Text("Add Tag")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    !newTag.isEmpty ?
                    Color.hex("5E5CE6") :
                    Color.hex("8E8E93").opacity(0.3)
                )
                .cornerRadius(12)
        }
        .disabled(newTag.isEmpty)
    }
    
    private func saveCard() {
        let newCard = Card(context: viewContext)
        newCard.id = UUID()
        newCard.front = viewModel.front
        newCard.back = viewModel.back
        newCard.tags = viewModel.tags
        
        // Initialize review state
        newCard.interval = 0.0  // Start with 0 interval for new cards
        newCard.ease = 2.5     // Default ease factor
        newCard.dueDate = Date() // Due immediately
        newCard.streak = 0
        newCard.reviewCount = 0
        newCard.createdAt = Date()
        newCard.modifiedAt = Date()
        newCard.lastReviewDate = nil
        
        do {
            try viewContext.save()
            viewModel.reset()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

struct EditorCardView: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @State private var showPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showPreview.toggle() }) {
                    Image(systemName: showPreview ? "text.alignleft" : "eye")
                        .foregroundColor(Color.hex("5E5CE6"))
                }
            }
            
            if showPreview {
                MarkdownText(text: text)
                    .padding(16)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hex("2C2C2E"), lineWidth: 1)
                    )
            } else {
                TextEditor(text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.hex("2C2C2E"), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.hex("2C2C2E"), lineWidth: 1)
        )
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(selectedTab: .constant(0))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 
