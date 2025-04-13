import SwiftUI

struct NotificationsSettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = false
    @AppStorage("notificationTime") private var notificationTime = Date()
    @AppStorage("notificationDays") private var notificationDays: Int = 127 // All days selected (7-bit mask)
    
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $enableNotifications) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Color.hex("5E5CE6"))
                        Text("Enable Notifications")
                            .foregroundColor(.white)
                    }
                }
                .tint(Color.hex("5E5CE6"))
                .listRowBackground(Color.hex("1C1C1E"))
                
                if enableNotifications {
                    DatePicker(
                        "Reminder Time",
                        selection: $notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .foregroundColor(.white)
                    .listRowBackground(Color.hex("1C1C1E"))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repeat")
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<7) { index in
                                let isSelected = (notificationDays & (1 << index)) != 0
                                Button(action: { toggleDay(index) }) {
                                    Text(daysOfWeek[index])
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(isSelected ? .white : Color.hex("8E8E93"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.hex("5E5CE6") : Color.hex("2C2C2E"))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.hex("1C1C1E"))
                }
            }
            
            if enableNotifications {
                Section(footer: Text("You'll receive a notification at the selected time on the chosen days when you have cards due for review.").foregroundColor(.gray)) {
                    EmptyView()
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func toggleDay(_ index: Int) {
        notificationDays ^= (1 << index)
    }
} 