//
//  PrayerTime.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import SwiftData

/// Represents prayer times for a specific date and location
@Model
class PrayerTime {
    // MARK: - Properties
    
    /// The date these prayer times are for
    var date: Date
    
    /// Fajr (dawn) prayer time
    var fajr: Date
    
    /// Dhuhr (noon) prayer time
    var dhuhr: Date
    
    /// Asr (afternoon) prayer time
    var asr: Date
    
    /// Maghrib (sunset) prayer time
    var maghrib: Date
    
    /// Isha (night) prayer time
    var isha: Date
    
    /// Hijri date string (e.g., "15 Sha'ban 1447")
    var hijriDate: String
    
    /// Location these prayer times are calculated for
    var location: Location
    
    // MARK: - Initialization
    
    init(
        date: Date,
        fajr: Date,
        dhuhr: Date,
        asr: Date,
        maghrib: Date,
        isha: Date,
        hijriDate: String,
        location: Location
    ) {
        self.date = date
        self.fajr = fajr
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.hijriDate = hijriDate
        self.location = location
    }
    
    // MARK: - Computed Properties
    
    /// Returns all prayers as an array of tuples (name, time)
    var allPrayers: [(name: String, time: Date)] {
        return [
            ("Fajr", fajr),
            ("Dhuhr", dhuhr),
            ("Asr", asr),
            ("Maghrib", maghrib),
            ("Isha", isha)
        ]
    }
    
    /// Returns the current prayer (the one that has just passed)
    /// Returns nil if current time is before Fajr
    var currentPrayer: (name: String, time: Date)? {
        let now = Date()
        
        // If before Fajr, there's no current prayer for today
        if now < fajr {
            return nil
        }
        
        // Find the most recent prayer that has passed
        let passedPrayers = allPrayers.filter { $0.time <= now }
        return passedPrayers.last
    }
    
    /// Returns the next upcoming prayer
    /// Returns nil if all prayers for the day have passed
    var nextPrayer: (name: String, time: Date)? {
        let now = Date()
        
        // Find the first prayer that hasn't happened yet
        let upcomingPrayers = allPrayers.filter { $0.time > now }
        return upcomingPrayers.first
    }
    
    /// Returns the number of prayers remaining for the day
    var remainingPrayersCount: Int {
        let now = Date()
        return allPrayers.filter { $0.time > now }.count
    }
    
    /// Checks if a specific prayer has passed
    func hasPrayerPassed(_ prayerName: String) -> Bool {
        let now = Date()
        
        switch prayerName {
        case "Fajr": return now >= fajr
        case "Dhuhr": return now >= dhuhr
        case "Asr": return now >= asr
        case "Maghrib": return now >= maghrib
        case "Isha": return now >= isha
        default: return false
        }
    }
}
