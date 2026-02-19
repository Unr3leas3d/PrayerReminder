//
//  DateFormatter+Extensions.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation

extension DateFormatter {
    /// Formatter for prayer times (e.g., "3:45 PM")
    static let prayerTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    /// Formatter for full date (e.g., "Monday, February 17, 2026")
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    /// Formatter for short date (e.g., "Feb 17, 2026")
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    /// Formatter for day of week (e.g., "Monday")
    static let dayOfWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

extension Date {
    /// Format time as "h:mm a" (e.g., "3:45 PM")
    var prayerTimeString: String {
        DateFormatter.prayerTime.string(from: self)
    }
    
    /// Format as full date string (e.g., "Monday, February 17, 2026")
    var fullDateString: String {
        DateFormatter.fullDate.string(from: self)
    }
    
    /// Format as short date string (e.g., "Feb 17, 2026")
    var shortDateString: String {
        DateFormatter.shortDate.string(from: self)
    }
    
    /// Get day of week (e.g., "Monday")
    var dayOfWeekString: String {
        DateFormatter.dayOfWeek.string(from: self)
    }
    
    /// Get time until this date as a human-readable string
    /// Examples: "in 2 hours 34 minutes", "in 45 minutes", "in 1 hour"
    func timeUntilString() -> String {
        let now = Date()
        let interval = self.timeIntervalSince(now)
        
        guard interval > 0 else {
            return "now"
        }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "in \(hours) hour\(hours > 1 ? "s" : "") \(minutes) minute\(minutes > 1 ? "s" : "")"
        } else if hours > 0 {
            return "in \(hours) hour\(hours > 1 ? "s" : "")"
        } else if minutes > 0 {
            return "in \(minutes) minute\(minutes > 1 ? "s" : "")"
        } else {
            return "in less than a minute"
        }
    }
    
    /// Get compact time until string for widgets
    /// Examples: "2h 34m", "45m", "1h"
    func compactTimeUntilString() -> String {
        let now = Date()
        let interval = self.timeIntervalSince(now)
        
        guard interval > 0 else {
            return "now"
        }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
    
    /// Check if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if this date has passed
    var hasPassed: Bool {
        self < Date()
    }
}
