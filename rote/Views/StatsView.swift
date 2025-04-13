import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var selectedRange: TimeRange = .week
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    private var stats: Statistics {
        calculateStats(for: selectedRange)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time range picker
                        TimeRangePicker(selectedRange: $selectedRange)
                            .padding(.horizontal)
                        
                        // Stats overview
                        HStack(spacing: 16) {
                            AnalyticsStatBox(
                                title: "Reviews",
                                value: "\(stats.totalReviews)",
                                icon: "chart.bar.fill",
                                color: Color.hex(accentColor)
                            )
                            
                            AnalyticsStatBox(
                                title: "Retention",
                                value: "\(Int(stats.retentionRate * 100))%",
                                icon: "brain.fill",
                                color: Color.green
                            )
                        }
                        .padding(.horizontal)
                        
                        // Progress graph
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Progress")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            ReviewGraph(data: stats.dailyReviews)
                                .frame(height: 200)
                        }
                        .padding()
                        .background(Color.hex("1C1C1E"))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Tag distribution
                        if !stats.tagCounts.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Tags")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                ForEach(Array(stats.tagCounts.sorted { $0.value > $1.value }), id: \.key) { tag, count in
                                    HStack {
                                        Text(tag)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(count)")
                                            .foregroundColor(Color.hex("8E8E93"))
                                    }
                                    .font(.system(size: 15))
                                }
                            }
                            .padding()
                            .background(Color.hex("1C1C1E"))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func calculateStats(for range: TimeRange) -> Statistics {
        let now = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -range.days, to: now) ?? now
        
        let reviews = cards.flatMap { card in
            card.reviews?.allObjects as? [Review] ?? []
        }
        
        let filteredReviews = reviews.filter { review in
            guard let date = review.date else { return false }
            return date >= startDate && date <= now
        }
        
        // Calculate daily reviews
        var dailyReviews: [(date: Date, count: Int)] = []
        for dayOffset in 0..<range.days {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let count = filteredReviews.filter { review in
                guard let date = review.date else { return false }
                return date >= dayStart && date < dayEnd
            }.count
            
            dailyReviews.append((date: dayStart, count: count))
        }
        
        // Calculate retention rate
        let totalReviews = filteredReviews.count
        let correctReviews = filteredReviews.filter { review in
            review.rating == "good" || review.rating == "easy"
        }.count
        let retentionRate = totalReviews > 0 ? Double(correctReviews) / Double(totalReviews) : 0
        
        // Calculate tag counts
        let tagCounts = calculateTagCounts()
        
        return Statistics(
            totalReviews: totalReviews,
            retentionRate: retentionRate,
            dailyReviews: dailyReviews.reversed(),
            tagCounts: tagCounts
        )
    }
    
    private func calculateTagCounts() -> [String: Int] {
        var tagCounts: [String: Int] = [:]
        
        // Count cards for each tag
        for card in cards {
            for tag in card.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
    }
}

struct TimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        HStack {
            ForEach(TimeRange.allCases) { range in
                Button(action: { selectedRange = range }) {
                    Text(range.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selectedRange == range ? .white : Color(hex: "8E8E93"))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            selectedRange == range ?
                            Color(hex: "5E5CE6") :
                            Color(hex: "2C2C2E")
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
    }
}

struct AnalyticsStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color.hex("8E8E93"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(16)
    }
}

struct ReviewGraph: View {
    let data: [(date: Date, count: Int)]
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    private var maxCount: Int {
        data.map { $0.count }.max() ?? 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Graph
                ZStack(alignment: .bottom) {
                    // Background grid
                    VStack(spacing: 0) {
                        ForEach(0..<4) { i in
                            Divider()
                                .background(Color.hex("2C2C2E"))
                            if i < 3 {
                                Spacer()
                            }
                        }
                    }
                    
                    // Bars
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(data, id: \.date) { item in
                            VStack {
                                Rectangle()
                                    .fill(Color.hex(accentColor))
                                    .frame(height: geometry.size.height * CGFloat(item.count) / CGFloat(max(maxCount, 1)))
                                
                                Text(formatDate(item.date))
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.hex("8E8E93"))
                                    .rotationEffect(.degrees(-45))
                                    .offset(y: 20)
                            }
                        }
                    }
                }
                .padding(.bottom, 30) // Space for rotated labels
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case allTime = "All Time"
    
    var id: String { rawValue }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .allTime: return 3650 // 10 years
        }
    }
}

struct Statistics {
    let totalReviews: Int
    let retentionRate: Double
    let dailyReviews: [(date: Date, count: Int)]
    let tagCounts: [String: Int]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 