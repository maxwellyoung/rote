import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    // Time range for stats
    @State private var selectedRange: TimeRange = .week
    
    private var stats: Statistics {
        calculateStats(for: selectedRange)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Stats cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Reviews", value: "\(stats.totalReviews)")
                        StatCard(title: "Retention", value: "\(Int(stats.retentionRate * 100))%")
                        StatCard(title: "Due Today", value: "\(stats.dueToday)")
                        StatCard(title: "Streak", value: "\(stats.currentStreak) days")
                    }
                    .padding(.horizontal)
                    
                    // Review quality distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review Quality")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: stats.againPercentage, height: 24)
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: stats.goodPercentage, height: 24)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: stats.easyPercentage, height: 24)
                        }
                        .cornerRadius(8)
                        
                        HStack {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Again")
                            }
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Good")
                            }
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text("Easy")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Tag distribution
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cards by Tag")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(stats.tagCounts.sorted(by: { $0.value > $1.value }), id: \.key) { tag, count in
                            HStack {
                                Text(tag)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(count)")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func calculateStats(for range: TimeRange) -> Statistics {
        let now = Date()
        let calendar = Calendar.current
        let startDate: Date
        
        switch range {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now)!
        }
        
        // Calculate tag distribution
        var tagCounts: [String: Int] = [:]
        for card in cards {
            for tag in (card.tags ?? []) {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        // Calculate due today
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let dueToday = cards.filter { $0.dueDate ?? now <= endOfDay }.count
        
        // TODO: Add actual review history tracking for more accurate stats
        // For now, return mock data based on card counts
        return Statistics(
            totalReviews: cards.count * 3,
            retentionRate: 0.85,
            dueToday: dueToday,
            currentStreak: 5,
            againPercentage: 50,
            goodPercentage: 100,
            easyPercentage: 50,
            tagCounts: tagCounts
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    
    var id: String { rawValue }
}

struct Statistics {
    let totalReviews: Int
    let retentionRate: Double
    let dueToday: Int
    let currentStreak: Int
    let againPercentage: CGFloat
    let goodPercentage: CGFloat
    let easyPercentage: CGFloat
    let tagCounts: [String: Int]
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 