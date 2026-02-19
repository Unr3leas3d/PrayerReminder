//
//  Constants.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation

enum Constants {
    // MARK: - App Information
    
    static let appName = "Nur"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let appGroup = "group.com.ayubmohamed.PrayerReminder" // Replace with actual app group if needed
    
    // MARK: - Prayer Names
    
    static let prayerNames = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    
    // MARK: - Notification Timing Options (minutes before prayer)
    
    static let notificationTimingOptions = [0, 5, 10, 15]
    
    static func notificationTimingDisplayName(for minutes: Int) -> String {
        switch minutes {
        case 0: return "At prayer time"
        case 5: return "5 minutes before"
        case 10: return "10 minutes before"
        case 15: return "15 minutes before"
        default: return "\(minutes) minutes before"
        }
    }
    
    // MARK: - Cache
    
    static let maxCacheDays = 30
    
    // MARK: - UserDefaults Keys
    
    enum Defaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastLocationUpdate = "lastLocationUpdate"
    }
    
    // MARK: - Spacing and Sizing
    
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let defaultDuration: Double = 0.3
        static let quickDuration: Double = 0.2
        static let slowDuration: Double = 0.5
    }
    
    // MARK: - URLs
    
    enum URLs {
        static let privacyPolicy = "https://yourwebsite.com/privacy"
        static let termsOfService = "https://yourwebsite.com/terms"
        static let support = "mailto:support@yourwebsite.com"
    }
    
    // MARK: - Islamic Greetings
    
    static  let islamicGreetings = [
        "Assalamu Alaikum",
        "Peace be upon you",
        "Nur be with you"
    ]
    
    static func randomGreeting() -> String {
        islamicGreetings.randomElement() ?? "Assalamu Alaikum"
    }
}
