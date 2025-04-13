import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("accentColor") private var accentColor = "5E5CE6"
    @AppStorage("useCustomAccentColor") private var useCustomAccentColor = false
    @AppStorage("reminderTime") private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    
    private let defaultAccentColor = "5E5CE6"
    @State private var showingColorPicker = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Study Reminders", systemImage: "bell.badge")
                    }
                } header: {
                    Text("Notifications")
                }
                .listRowBackground(Color.hex("1C1C1E"))
                
                Section {
                    Toggle("Custom Accent Color", isOn: $useCustomAccentColor)
                    
                    if useCustomAccentColor {
                        ColorPicker("Accent Color", selection: .init(
                            get: { Color.hex(accentColor) },
                            set: { newColor in
                                if let components = UIColor(newColor).cgColor.components {
                                    let r = Int(components[0] * 255)
                                    let g = Int(components[1] * 255)
                                    let b = Int(components[2] * 255)
                                    accentColor = String(format: "%02X%02X%02X", r, g, b)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Appearance")
                }
                .listRowBackground(Color.hex("1C1C1E"))
                
                Section {
                    Link(destination: URL(string: "https://github.com/yourusername/rote")!) {
                        Label("View on GitHub", systemImage: "link")
                    }
                    
                    Link(destination: URL(string: "mailto:your@email.com")!) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                } header: {
                    Text("About")
                }
                .listRowBackground(Color.hex("1C1C1E"))
            }
            .navigationTitle("Settings")
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .task {
                let settings = await NotificationManager.shared.getNotificationSettings()
                notificationStatus = settings.authorizationStatus
                if notificationStatus != .authorized {
                    reminderEnabled = false
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color.hex("8E8E93"))
        }
        .padding(.vertical, 4)
    }
} 