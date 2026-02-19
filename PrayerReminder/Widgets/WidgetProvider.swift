import WidgetKit
import SwiftData
import Foundation

struct PrayerTimelineProvider: TimelineProvider {
    typealias Entry = PrayerWidgetEntry
    
    // We'll use a shared model container if possible, otherwise mock data
    private var modelContainer: ModelContainer? {
        let schema = Schema([UserSettings.self, PrayerTime.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try? ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    func placeholder(in context: Context) -> Entry {
        .mock
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(.mock)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        var entries: [Entry] = []
        
        let context = modelContainer?.mainContext
        
        // Fetch settings
        let settingsFetch = FetchDescriptor<UserSettings>()
        let settings = (try? context?.fetch(settingsFetch))?.first
        let userName = settings?.userName ?? "User"
        
        // Fetch today's prayer times
        let startOfToday = Calendar.current.startOfDay(for: now)
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let prayerFetch = FetchDescriptor<PrayerTime>(
            predicate: #Predicate<PrayerTime> { $0.date >= startOfToday && $0.date < endOfToday }
        )
        
        let prayerTime = (try? context?.fetch(prayerFetch))?.first
        let nextPrayer = prayerTime?.nextPrayer
        
        // Create an entry for now
        let entry = PrayerWidgetEntry(
            date: now,
            prayerTime: prayerTime,
            nextPrayer: nextPrayer,
            userName: userName
        )
        entries.append(entry)
        
        // Schedule next update at the next prayer time, or at midnight
        var nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        if let next = nextPrayer?.time {
            nextUpdate = next.addingTimeInterval(60) // 1 minute after prayer
        }
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}
