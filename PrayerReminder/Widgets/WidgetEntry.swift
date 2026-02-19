import WidgetKit
import Foundation

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let prayerTime: PrayerTime?
    let nextPrayer: (name: String, time: Date)?
    let userName: String
    
    static var mock: PrayerWidgetEntry {
        // Create a mock prayer time for today
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        let mockPrayers = PrayerTime(
            date: startOfDay,
            fajr: calendar.date(byAdding: .hour, value: 5, to: startOfDay)!,
            dhuhr: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            asr: calendar.date(byAdding: .hour, value: 15, to: startOfDay)!,
            maghrib: calendar.date(byAdding: .hour, value: 18, to: startOfDay)!,
            isha: calendar.date(byAdding: .hour, value: 20, to: startOfDay)!,
            hijriDate: "15 Sha'ban 1447",
            location: .cupertino
        )
        
        return PrayerWidgetEntry(
            date: now,
            prayerTime: mockPrayers,
            nextPrayer: ("Dhuhr", calendar.date(byAdding: .hour, value: 12, to: startOfDay)!),
            userName: "User"
        )
    }
}
