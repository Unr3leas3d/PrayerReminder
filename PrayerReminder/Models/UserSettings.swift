//
//  UserSettings.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import SwiftData

/// Represents user preferences and settings (synced via iCloud)
@Model
class UserSettings {
    // MARK: - Profile Settings
    
    /// User's name (used for personalization)
    var userName: String
    
    /// User's preferred location for prayer times
    var location: Location
    
    // MARK: - Prayer Settings
    
    /// Selected calculation method for prayer times
    var calculationMethodRawValue: Int
    
    /// Which prayers have notifications enabled
    /// Format: ["Fajr": true, "Dhuhr": false, ...]
    var enabledPrayers: [String: Bool]
    
    /// Notification timing in minutes before prayer time
    /// Format: ["Fajr": 0, "Dhuhr": 5, ...] where 0 = at prayer time
    var notificationTimings: [String: Int]
    
    // MARK: - Display Settings
    
    /// Whether to show Gregorian date on main screen
    var showGregorianDate: Bool
    
    /// App theme preference
    var themeRawValue: Int
    
    /// User's preferred time format (12h, 24h, or system)
    var timeFormatRawValue: Int = 0
    
    // MARK: - Location Settings
    
    /// Whether to automatically update location when device moves significantly
    var autoUpdateLocation: Bool
    
    // MARK: - Sync Settings
    
    /// Last time settings were synced with iCloud
    var lastSyncDate: Date?
    
    // MARK: - Initialization
    
    init(
        userName: String = "",
        location: Location = .cupertino,
        calculationMethod: CalculationMethod? = nil,
        enabledPrayers: [String: Bool]? = nil,
        notificationTimings: [String: Int]? = nil,
        showGregorianDate: Bool = true,
        theme: AppTheme = .system,
        timeFormat: TimeFormat = .system,
        autoUpdateLocation: Bool = false
    ) {
        self.userName = userName
        self.location = location
        
        // Determine calculation method:
        // 1. Use provided method if any
        // 2. Or recommend based on country code
        // 3. Fallback to default (.muslimWorldLeague)
        let method = calculationMethod ?? 
                     (location.countryCode.map { CalculationMethod.recommended(forCountryCode: $0) }) ?? 
                     .muslimWorldLeague
        
        self.calculationMethodRawValue = method.rawValue
        
        // Default: all prayers enabled
        self.enabledPrayers = enabledPrayers ?? [
            "Fajr": true,
            "Dhuhr": true,
            "Asr": true,
            "Maghrib": true,
            "Isha": true
        ]
        
        // Default: all notifications at prayer time (0 minutes before)
        self.notificationTimings = notificationTimings ?? [
            "Fajr": 0,
            "Dhuhr": 0,
            "Asr": 0,
            "Maghrib": 0,
            "Isha": 0
        ]
        
        self.showGregorianDate = showGregorianDate
        self.themeRawValue = theme.rawValue
        self.timeFormatRawValue = timeFormat.rawValue
        self.autoUpdateLocation = autoUpdateLocation
        self.lastSyncDate = nil
    }
    
    // MARK: - Computed Properties
    
    /// Calculation method (safe unwrap from raw value)
    var calculationMethod: CalculationMethod {
        get {
            CalculationMethod(rawValue: calculationMethodRawValue) ?? .muslimWorldLeague
        }
        set {
            calculationMethodRawValue = newValue.rawValue
        }
    }
    
    /// App theme (safe unwrap from raw value)
    var theme: AppTheme {
        get {
            AppTheme(rawValue: themeRawValue) ?? .system
        }
        set {
            themeRawValue = newValue.rawValue
        }
    }
    
    /// Time format (safe unwrap from raw value)
    var timeFormat: TimeFormat {
        get {
            TimeFormat(rawValue: timeFormatRawValue) ?? .system
        }
        set {
            timeFormatRawValue = newValue.rawValue
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if a specific prayer has notifications enabled
    func isPrayerEnabled(_ prayerName: String) -> Bool {
        return enabledPrayers[prayerName] ?? true
    }
    
    /// Get notification timing for a specific prayer (in minutes before)
    func notificationTiming(for prayerName: String) -> Int {
        return notificationTimings[prayerName] ?? 0
    }
    
    /// Enable or disable notifications for a specific prayer
    func setPrayerEnabled(_ prayerName: String, enabled: Bool) {
        enabledPrayers[prayerName] = enabled
    }
    
    /// Set notification timing for a specific prayer
    func setNotificationTiming(for prayerName: String, minutesBefore: Int) {
        notificationTimings[prayerName] = minutesBefore
    }
    
    /// Count of enabled prayers
    var enabledPrayersCount: Int {
        return enabledPrayers.values.filter { $0 }.count
    }
}

// MARK: - AppTheme Enum

/// App theme options
enum AppTheme: Int, Codable, CaseIterable, Identifiable {
    case light = 0
    case dark = 1
    case system = 2
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - TimeFormat Enum

/// Time format options
enum TimeFormat: Int, Codable, CaseIterable, Identifiable {
    case system = 0
    case format12h = 1
    case format24h = 2
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .format12h: return "12-Hour (AM/PM)"
        case .format24h: return "24-Hour"
        }
    }
}
