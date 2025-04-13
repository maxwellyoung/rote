import SwiftUI
import CoreData

struct NotificationSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTime") private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var showingAuthAlert = false
    @State private var authAlertMessage = ""
    
    var body: some View {
        Form(content: {
            Toggle("Enable Notifications", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { oldValue, newValue in
                    if newValue {
                        requestNotificationPermission()
                    } else {
                        NotificationManager.shared.cancelReminders()
                    }
                }
            
            if reminderEnabled {
                Section {
                    DatePicker("Daily Reminder Time",
                              selection: $reminderTime,
                              displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { oldValue, newValue in
                            scheduleNotification()
                        }
                }
            }
        })
        .listRowBackground(Color.hex("1C1C1E"))
        .navigationTitle("Study Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notification Permission", isPresented: $showingAuthAlert) {
            Button("OK") {}
        } message: {
            Text(authAlertMessage)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                if granted {
                    scheduleNotification()
                } else {
                    reminderEnabled = false
                    showingAuthAlert = true
                    authAlertMessage = "Please enable notifications in Settings to receive study reminders."
                }
            }
        }
    }
    
    private func scheduleNotification() {
        Task {
            let dueCount = NotificationManager.shared.getDueCardCount(in: viewContext)
            await NotificationManager.shared.scheduleReminder(
                at: reminderTime,
                title: "Time to Study!",
                body: "You have \(dueCount) cards due for review."
            )
        }
    }
} 