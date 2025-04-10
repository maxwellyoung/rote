import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Card.dueDate, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<Card>
    
    @State private var selectedRange: TimeRange = .week
    
    private var stats: Statistics {
        calculateStats(for: selectedRange)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.hex("1A1A1A"), Color.hex("0A0A0A")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Today's stats
                    VStack(spacing: 16) {
                        HStack {
                            Text("Today")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.hex("8E8E93"))
                            Spacer()
                        }
                        
                        Text("12")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(16)
                    
                    // Weekly stats
                    VStack(spacing: 16) {
                        HStack {
                            Text("Last 7 Days")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.hex("8E8E93"))
                            Spacer()
                        }
                        
                        Text("84")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(16)
                    
                    // Monthly stats
                    VStack(spacing: 16) {
                        HStack {
                            Text("Last 30 Days")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.hex("8E8E93"))
                            Spacer()
                        }
                        
                        Text("342")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.hex("1C1C1E"))
                    .cornerRadius(16)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Stats")
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
        
        var tagCounts: [String: Int] = [:]
        for card in cards {
            for tag in (card.tags ?? []) {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let dueToday = cards.filter { $0.dueDate ?? now <= endOfDay }.count
        
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "2C2C2E"), lineWidth: 1)
        )
    }
}

struct ReviewQualityBar: View {
    let label: String
    let value: CGFloat
    let total: CGFloat
    let color: Color
    
    var percentage: Int {
        Int((value / total) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "2C2C2E"))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (value / total))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
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