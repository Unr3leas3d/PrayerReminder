//
//  NotificationService.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import UserNotifications

/// Service for managing prayer time notifications
@MainActor
class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    // MARK: - Properties
    
    @Published var isAuthorized = false
    @Published var shouldNavigateToHome = false
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        // Clear any existing badge
        notificationCenter.setBadgeCount(0)
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Play sound and show banner even if app is in foreground
        completionHandler([.banner, .sound])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        Task { @MainActor in
            shouldNavigateToHome = true
        }
        completionHandler()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission from user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound]
            )
            isAuthorized = granted
            
            if granted {
                print("✅ Notification permission granted")
            } else {
                print(" Notification permission denied")
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Notification Scheduling
    
    /// Schedule notifications for all enabled prayers
    func scheduleNotifications(
        for prayerTimes: PrayerTime,
        settings: UserSettings
    ) async {
        // Cancel existing notifications first
        notificationCenter.removeAllPendingNotificationRequests()
        
        guard isAuthorized else {
            print("⚠️ Cannot schedule notifications - not authorized")
            return
        }
        
        var scheduledCount = 0
        
        // Schedule notification for each enabled prayer
        for (prayerName, prayerTime) in prayerTimes.allPrayers {
            guard settings.isPrayerEnabled(prayerName) else {
                continue
            }
            
            let minutesBefore = settings.notificationTiming(for: prayerName)
            let notificationTime = Calendar.current.date(
                byAdding: .minute,
                value: -minutesBefore,
                to: prayerTime
            )!
            
            // Only schedule if notification time is in the future
            if notificationTime > Date() {
                await scheduleNotification(
                    for: prayerName,
                    at: notificationTime,
                    userName: settings.userName,
                    minutesBefore: minutesBefore
                )
                scheduledCount += 1
            }
        }
        
        
        print("📅 Scheduled \(scheduledCount) prayer notifications")
    }
    
    /// Schedule a single notification
    private func scheduleNotification(
        for prayerName: String,
        at time: Date,
        userName: String,
        minutesBefore: Int
    ) async {
        let content = UNMutableNotificationContent()
        content.title = "\(prayerName) Prayer"
        
        if minutesBefore == 0 {
            if userName.isEmpty {
                content.body = "It's time for \(prayerName) prayer"
            } else {
                content.body = "\(userName), it's time for \(prayerName) prayer"
            }
        } else {
            if userName.isEmpty {
                content.body = "\(prayerName) prayer in \(minutesBefore) minutes"
            } else {
                content.body = "\(userName), \(prayerName) prayer in \(minutesBefore) minutes"
            }
        }
        
        content.sound = .default
        content.categoryIdentifier = "PRAYER_REMINDER"
        
        // Create date components for trigger
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: time
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let identifier = "\(prayerName)_\(time.timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled \(prayerName) notification for \(time)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    
    
    // MARK: - Notification Management
    
    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all notifications")
    }
    
    /// Get list of pending notifications (for debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Cancel notifications for a specific prayer
    func cancelNotification(for prayerName: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [prayerName])
        print("🗑️ Cancelled \(prayerName) notification")
    }
    
    // MARK: - Test Notification
    
    /// Schedule a test notification 5 seconds from now
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is how your prayer reminders will appear."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "TEST_NOTIFICATION",
            content: content,
            trigger: trigger
        )
        
        Task {
            do {
                try await notificationCenter.add(request)
                print("✅ Scheduled test notification for 5 seconds from now")
            } catch {
                print("Error scheduling test notification: \(error)")
            }
        }
    }
}
