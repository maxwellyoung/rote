import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func getNotificationSettings() async -> UNNotificationSettings {
        await UNUserNotificationCenter.current().notificationSettings()
    }
    
    func scheduleReminder(at date: Date, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "studyReminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    func cancelReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getDueCardCount(in context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest<Card>(entityName: "Card")
        fetchRequest.predicate = NSPredicate(format: "dueDate <= %@", Date() as NSDate)
        return (try? context.count(for: fetchRequest)) ?? 0
    }
} 