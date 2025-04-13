import SwiftUI
import CoreData
import Charts

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.createdAt, ascending: true)],
        animation: .default
    ) private var cards: FetchedResults<Card>
    @FetchRequest(
        entity: Review.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Review.date, ascending: true)],
        animation: .default
    ) private var reviews: FetchedResults<Review>
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedMetric = Metric.retention
    @State private var showingTagStats = false
    
    private enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            case .all: return Int.max
            }
        }
    }
    
    private enum Metric: String, CaseIterable {
        case retention = "Retention"
        case reviews = "Reviews"
        case streak = "Streak"
    }
    
    private var stats: StudyStats {
        let now = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: now) ?? now
        
        let periodReviews = reviews.filter { review in
            guard let date = review.date else { return false }
            return date >= startDate
        }
        
        let totalReviews = periodReviews.count
        let correctReviews = periodReviews.filter { review in
            switch review.rating {
            case "Good", "Easy": return true
            default: return false
            }
        }.count
        let retention = totalReviews > 0 ? Double(correctReviews) / Double(totalReviews) : 0
        
        // Calculate daily review counts
        var dailyReviews: [DailyReview] = []
        var currentDate = startDate
        
        while currentDate <= now {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayReviews = periodReviews.filter { review in
                guard let date = review.date else { return false }
                return date >= dayStart && date < dayEnd
            }
            
            let correct = dayReviews.filter { review in
                switch review.rating {
                case "Good", "Easy": return true
                default: return false
                }
            }.count
            dailyReviews.append(DailyReview(
                date: currentDate,
                total: dayReviews.count,
                correct: correct
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Calculate tag performance
        var tagStats: [TagStat] = []
        let allTags = Set(cards.flatMap { $0.tags })
        
        for tag in allTags {
            let tagReviews = periodReviews.filter { review in
                guard let card = review.card else { return false }
                return card.tags.contains(tag)
            }
            let tagTotal = tagReviews.count
            let tagCorrect = tagReviews.filter { review in
                switch review.rating {
                case "Good", "Easy": return true
                default: return false
                }
            }.count
            let tagRetention = tagTotal > 0 ? Double(tagCorrect) / Double(tagTotal) : 0
            
            tagStats.append(TagStat(
                tag: tag,
                reviews: tagTotal,
                retention: tagRetention
            ))
        }
        
        return StudyStats(
            totalReviews: totalReviews,
            correctReviews: correctReviews,
            retention: retention,
            dailyReviews: dailyReviews,
            tagStats: tagStats.sorted { $0.reviews > $1.reviews }
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Summary cards
                    HStack(spacing: 16) {
                        AnalyticsStatCard(
                            title: "Reviews",
                            value: "\(stats.totalReviews)",
                            icon: "chart.bar.fill",
                            color: "FF9500"
                        )
                        
                        AnalyticsStatCard(
                            title: "Retention",
                            value: String(format: "%.0f%%", stats.retention * 100),
                            icon: "brain.fill",
                            color: "34C759"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Chart {
                            ForEach(stats.dailyReviews) { daily in
                                LineMark(
                                    x: .value("Date", daily.date),
                                    y: .value("Reviews", daily.total)
                                )
                                .foregroundStyle(Color.hex(accentColor))
                                
                                AreaMark(
                                    x: .value("Date", daily.date),
                                    y: .value("Reviews", daily.total)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.hex(accentColor).opacity(0.2),
                                            Color.hex(accentColor).opacity(0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: selectedTimeRange == .week ? 1 : 7)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(date.formatted(.dateTime.day()))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    Text("\(value.as(Int.self) ?? 0)")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Tag performance
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Tag Performance")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                showingTagStats = true
                            } label: {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(Color.hex(accentColor))
                            }
                        }
                        
                        ForEach(stats.tagStats.prefix(3)) { tagStat in
                            TagStatRow(stat: tagStat)
                        }
                    }
                    .padding()
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingTagStats) {
                TagStatsView(stats: stats.tagStats)
            }
        }
    }
}

// MARK: - Supporting Views
private struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.hex("1C1C1E"))
        .cornerRadius(10)
        .overlay(
            Rectangle()
                .fill(Color.hex(color))
                .frame(height: 2)
                .padding(.horizontal)
                .offset(y: -2),
            alignment: .top
        )
    }
}

private struct TagStatRow: View {
    let stat: TagStat
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    
    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .foregroundColor(Color.hex(accentColor))
                .font(.system(size: 14))
            
            Text(stat.tag)
                .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(stat.reviews) reviews")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(String(format: "%.0f%% retention", stat.retention * 100))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct TagStatsView: View {
    let stats: [TagStat]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(stats) { stat in
                    TagStatRow(stat: stat)
                        .listRowBackground(Color.hex("1C1C1E"))
                }
            }
            .listStyle(.plain)
            .navigationTitle("Tag Statistics")
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
}

// MARK: - Data Models
private struct StudyStats {
    let totalReviews: Int
    let correctReviews: Int
    let retention: Double
    let dailyReviews: [DailyReview]
    let tagStats: [TagStat]
}

private struct DailyReview: Identifiable {
    let id = UUID()
    let date: Date
    let total: Int
    let correct: Int
}

private struct TagStat: Identifiable {
    let id = UUID()
    let tag: String
    let reviews: Int
    let retention: Double
} 