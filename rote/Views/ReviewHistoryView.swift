import SwiftUI
import CoreData
import Charts

struct ReviewHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Review.date, ascending: false)],
        animation: .default
    ) private var reviews: FetchedResults<Review>
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedReview: Review?
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    private var filteredReviews: [Review] {
        let cutoffDate = Calendar.current.date(
            byAdding: .day,
            value: -selectedTimeRange.days,
            to: Date()
        ) ?? Date()
        
        return reviews.filter { review in
            review.date ?? Date() >= cutoffDate
        }
    }
    
    private var reviewsByDate: [(date: Date, reviews: [Review])] {
        let grouped = Dictionary(grouping: filteredReviews) { review in
            Calendar.current.startOfDay(for: review.date ?? Date())
        }
        return grouped.map { (date: $0.key, reviews: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    private var retentionRate: Double {
        let total = Double(filteredReviews.count)
        guard total > 0 else { return 0 }
        
        let successful = Double(filteredReviews.filter { review in
            review.rating == "Good" || review.rating == "Easy"
        }.count)
        
        return (successful / total) * 100
    }
    
    private var averageInterval: Double {
        let intervals = filteredReviews.compactMap { $0.interval }
        return intervals.isEmpty ? 0 : intervals.reduce(0, +) / Double(intervals.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Stats overview
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ReviewStatCard(
                            title: "Reviews",
                            value: "\(filteredReviews.count)",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )
                        
                        ReviewStatCard(
                            title: "Retention",
                            value: String(format: "%.0f%%", retentionRate),
                            icon: "brain.head.profile",
                            color: .green
                        )
                        
                        ReviewStatCard(
                            title: "Avg Interval",
                            value: String(format: "%.1fd", averageInterval),
                            icon: "calendar",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Review distribution chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Review Distribution")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Chart(reviewsByDate, id: \.date) { day in
                            BarMark(
                                x: .value("Date", day.date),
                                y: .value("Reviews", day.reviews.count)
                            )
                            .foregroundStyle(Color.hex("5E5CE6"))
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.day().month())
                            }
                        }
                    }
                    .padding()
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Review history list
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Reviews")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(reviewsByDate, id: \.date) { day in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(day.reviews, id: \.id) { review in
                                    ReviewRow(review: review)
                                        .onTapGesture {
                                            selectedReview = review
                                        }
                                }
                            }
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                    .padding()
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Review History")
            .sheet(item: $selectedReview) { review in
                ReviewDetailView(review: review)
            }
        }
    }
}

struct ReviewStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.hex("1C1C1E"))
        .cornerRadius(12)
    }
}

struct ReviewRow: View {
    let review: Review
    
    private var ratingColor: Color {
        switch review.rating {
        case "Again": return .red
        case "Good": return .green
        case "Easy": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(review.card?.front ?? "")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(review.card?.back ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(review.rating ?? "")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ratingColor)
                
                Text("\(String(format: "%.1fd", review.interval))d")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ReviewDetailView: View {
    let review: Review
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Card content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Front")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        MarkdownText(text: review.card?.front ?? "")
                            .font(.system(size: 17))
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        Text("Back")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        MarkdownText(text: review.card?.back ?? "")
                            .font(.system(size: 17))
                    }
                    .padding()
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                    
                    // Review details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Review Details")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ReviewDetailRow(title: "Rating", value: review.rating ?? "")
                        ReviewDetailRow(title: "Interval", value: "\(String(format: "%.1f", review.interval)) days")
                        ReviewDetailRow(title: "Ease", value: String(format: "%.2f", review.ease))
                        if let date = review.date {
                            ReviewDetailRow(title: "Date", value: date.formatted())
                        }
                    }
                    .padding()
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Review Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ReviewDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.system(size: 15))
    }
}

struct ReviewHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewHistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
} 