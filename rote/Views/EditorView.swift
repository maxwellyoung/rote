import SwiftUI

struct EditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = CardViewModel()
    @State private var showingTags = false
    @State private var newTag = ""
    @Binding var selectedTab: Int
    
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
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Tags")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if viewModel.tags.isEmpty {
                                Text("No tags added yet")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "8E8E93"))
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
                            
                            Button(action: { showingTags = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color(hex: "5E5CE6"))
                                    Text("Add Tag")
                                        .foregroundColor(Color(hex: "5E5CE6"))
                                }
                                .font(.system(size: 17, weight: .medium))
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                        )
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveCard()
                        selectedTab = 0
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(viewModel.isValid ? Color(hex: "5E5CE6") : Color(hex: "8E8E93"))
                    }
                    .disabled(!viewModel.isValid)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.reset()
                        selectedTab = 0
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Color(hex: "8E8E93"))
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
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1A1A1A"), Color(hex: "0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    TextField("", text: $newTag)
                        .placeholder(when: newTag.isEmpty) {
                            Text("Enter tag name")
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                        )
                        .autocapitalization(.none)
                    
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
                                Color(hex: "5E5CE6") :
                                Color(hex: "8E8E93").opacity(0.3)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(newTag.isEmpty)
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
                    .foregroundColor(Color(hex: "5E5CE6"))
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

struct EditorCardView: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            TextEditor(text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .font(.system(size: 17))
                .foregroundColor(.white)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(16)
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
                )
        }
        .padding(16)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }
}

struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(tag)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "5E5CE6"))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(hex: "5E5CE6"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "5E5CE6").opacity(0.1))
        .cornerRadius(8)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(selectedTab: .constant(0))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 