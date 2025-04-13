import SwiftUI

struct ReviewSettingsView: View {
    @AppStorage("initialInterval") private var initialInterval = 1.0
    @AppStorage("easyBonus") private var easyBonus = 1.3
    @AppStorage("intervalModifier") private var intervalModifier = 1.0
    @AppStorage("maximumInterval") private var maximumInterval = 36500.0 // 100 years
    
    var body: some View {
        List {
            Section(header: Text("Intervals").foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Initial Interval")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(initialInterval)) days")
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    Slider(value: $initialInterval, in: 1...7, step: 1)
                        .tint(Color.hex("5E5CE6"))
                }
                .listRowBackground(Color.hex("1C1C1E"))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Easy Bonus")
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1fx", easyBonus))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    Slider(value: $easyBonus, in: 1.1...1.5, step: 0.1)
                        .tint(Color.hex("5E5CE6"))
                }
                .listRowBackground(Color.hex("1C1C1E"))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Interval Modifier")
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1fx", intervalModifier))
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    Slider(value: $intervalModifier, in: 0.5...1.5, step: 0.1)
                        .tint(Color.hex("5E5CE6"))
                }
                .listRowBackground(Color.hex("1C1C1E"))
            }
            
            Section(header: Text("Limits").foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Maximum Interval")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(maximumInterval)) days")
                            .foregroundColor(Color.hex("8E8E93"))
                    }
                    Slider(value: $maximumInterval, in: 365...36500, step: 365)
                        .tint(Color.hex("5E5CE6"))
                }
                .listRowBackground(Color.hex("1C1C1E"))
            }
            
            Section(header: Text("Info").foregroundColor(.gray), footer: Text("These settings affect how the spaced repetition algorithm schedules your reviews. Higher values mean longer intervals between reviews.").foregroundColor(.gray)) {
                EmptyView()
            }
        }
        .navigationTitle("Review Settings")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
} 