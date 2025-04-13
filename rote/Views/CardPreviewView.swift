import SwiftUI

struct CardPreviewView: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @State private var showingBack = false
    
    private var stateColor: Color {
        if !card.isDue {
            return .secondary
        }
        switch card.state {
        case "new": return .blue
        case "learning": return .orange
        case "review": return .green
        case "relearning": return .red
        default: return .gray
        }
    }
    
    private var stateText: String {
        if !card.isDue {
            if let nextReview = card.nextReviewAt {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                return "Due " + formatter.localizedString(for: nextReview, relativeTo: Date())
            }
            return "Not due yet"
        }
        switch card.state {
        case "new": return "New"
        case "learning": return "Learning (\(card.stepIndex + 1)/4)"
        case "review": return "Review"
        case "relearning": return "Relearning (\(card.stepIndex + 1)/4)"
        default: return "Unknown"
        }
    }
    
    private var progressValue: Double {
        switch card.state {
        case "new": return 0.0
        case "learning", "relearning": return Double(card.stepIndex + 1) / 4.0
        case "review": return 1.0
        default: return 0.0
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // State and Progress
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(stateColor)
                                .frame(width: 8, height: 8)
                            Text(stateText)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            if card.reviewCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("\(card.reviewCount) reviews")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        if card.state == "learning" || card.state == "relearning" {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(stateColor)
                                        .frame(width: geometry.size.width * progressValue, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Front")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.hex(accentColor))
                        MarkdownText(text: card.front ?? "")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    
                    if showingBack {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Back")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.hex(accentColor))
                            MarkdownText(text: card.back ?? "")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.hex("1C1C1E"))
                        .cornerRadius(12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if !showingBack {
                        Button(action: { withAnimation { showingBack = true } }) {
                            Text("Show Answer")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color.hex(accentColor))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.hex(accentColor).opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
                    if !card.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.hex(accentColor))
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.hex("1C1C1E"))
                        .cornerRadius(12)
                    }
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistics")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.hex(accentColor))
                        
                        HStack(spacing: 16) {
                            if let nextReview = card.nextReviewAt {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(nextReview.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                            
                            if card.interval > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.circlepath")
                                    Text("\(String(format: "%.1f", card.interval))d")
                                }
                            }
                            
                            if card.streak > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("\(card.streak)")
                                }
                            }
                            
                            if card.easeFactor != 2.5 {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                    Text(String(format: "%.1fx", card.easeFactor))
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                }
                .padding(16)
            }
            .navigationTitle("Card Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
} 