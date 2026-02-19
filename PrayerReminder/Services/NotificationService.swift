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
class NotificationService: ObservableObject {
    // MARK: - Properties
    
    @Published var isAuthorized = false
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission from user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
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
        
        // Update app badge to show remaining prayers
        await updateBadge(prayerTimes: prayerTimes)
        
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
    
    /// Update app badge to show number of remaining prayers
    private func updateBadge(prayerTimes: PrayerTime) async {
        let remainingPrayers = prayerTimes.remainingPrayersCount
        
        do {
            try await notificationCenter.setBadgeCount(remainingPrayers)
        } catch {
            print("Error updating badge: \(error)")
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
}
