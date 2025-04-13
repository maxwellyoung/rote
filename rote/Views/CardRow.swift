import SwiftUI

struct CardRow: View {
    let card: Card
    @State private var showingPreview = false
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    var body: some View {
        Button(action: { showingPreview = true }) {
            VStack(alignment: .leading, spacing: 12) {
                MarkdownText(text: card.front ?? "")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                if let back = card.back, !back.isEmpty {
                    MarkdownText(text: back)
                        .font(.system(size: 15))
                        .foregroundColor(Color.hex("8E8E93"))
                        .lineLimit(2)
                }
                
                if !card.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(card.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.hex(accentColor))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.hex(accentColor).opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                if let dueDate = card.dueDate {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 12, weight: .medium))
                        }
                        
                        if card.interval > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                Text("\(String(format: "%.1f", card.interval))d")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                    }
                    .foregroundColor(Color.hex("8E8E93"))
                }
            }
            .padding(.vertical, 12)
        }
        .sheet(isPresented: $showingPreview) {
            CardPreviewView(card: card)
        }
    }
} 