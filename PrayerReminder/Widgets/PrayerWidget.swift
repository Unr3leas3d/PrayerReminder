import SwiftUI
import WidgetKit

struct PrayerWidgetView: View {
    var entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .accessoryCircular {
            accessoryCircularView
        } else if family == .accessoryRectangular {
            accessoryRectangularView
        } else if family == .accessoryInline {
            accessoryInlineView
        } else {
            homeScreenView
        }
    }
    
    private var homeScreenView: some View {
        ZStack {
            Color.adaptiveBackground
            
            IslamicPatternView(opacity: 0.03)
            
            VStack(alignment: .leading, spacing: 8) {
                headerView
                
                Spacer()
                
                if let next = entry.nextPrayer {
                    nextPrayerView(next: next)
                } else if let prayers = entry.prayerTime {
                    allCompletedView
                } else {
                    noDataView
                }
                
                if family != .systemSmall {
                    Spacer()
                    footerView
                }
            }
            .padding()
        }
    }
    
    // MARK: - Accessory Views (Lock Screen)
    
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(entry.nextPrayer?.name.prefix(1) ?? "P")
                    .font(.system(size: 10, weight: .bold))
                Text(entry.nextPrayer?.time.formatted(.dateTime.hour().minute()) ?? "--:--")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
    }
    
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                Text(entry.nextPrayer?.name ?? "Prayer")
                    .font(.headline)
            }
            Text(entry.nextPrayer?.time.prayerTimeString ?? "--:--")
                .font(.title3)
                .bold()
            if let time = entry.nextPrayer?.time {
                Text(time.compactTimeUntilString())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var accessoryInlineView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
            Text("\(entry.nextPrayer?.name ?? "Prayer"): \(entry.nextPrayer?.time.prayerTimeString ?? "--:--")")
        }
    }
    
    // MARK: - Home Screen Components
    
    private var headerView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(.adaptivePrimary)
            
            if family != .systemSmall {
                Text(Constants.appName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.adaptivePrimary)
            }
            
            Spacer()
            
            if family == .systemLarge {
                Text(entry.prayerTime?.hijriDate ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.adaptiveTextSecondary)
            }
        }
    }
    
    private func nextPrayerView(next: (name: String, time: Date)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT PRAYER")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.adaptiveTextSecondary)
            
            Text(next.name)
                .font(.system(size: family == .systemSmall ? 22 : 28, weight: .black, design: .rounded))
                .foregroundColor(.adaptivePrimary)
            
            Text(next.time.prayerTimeString)
                .font(.system(size: family == .systemSmall ? 16 : 20, weight: .semibold, design: .rounded))
                .foregroundColor(.adaptiveText)
            
            if family != .systemSmall {
                Text(next.time.compactTimeUntilString())
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.adaptivePrimary)
                    .cornerRadius(8)
            }
        }
    }
    
    private var allCompletedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All prayers completed")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.adaptiveTextSecondary)
            Text("Alhamdulillah")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.adaptivePrimary)
        }
    }
    
    private var noDataView: some View {
        Text("Open app to sync prayer times")
            .font(.system(size: 12))
            .foregroundColor(.adaptiveTextSecondary)
    }
    
    private var footerView: some View {
        HStack {
            if let prayers = entry.prayerTime {
                let remaining = prayers.remainingPrayersCount
                Text("\(remaining) prayers remaining")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.adaptiveTextSecondary)
            }
            
            Spacer()
            
            Text(entry.date.formatted(.dateTime.hour().minute()))
                .font(.system(size: 10))
                .foregroundColor(.adaptiveTextSecondary.opacity(0.5))
        }
    }
}

struct PrayerWidget: Widget {
    let kind: String = "PrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Prayer Reminders")
        .description("Stay updated with your prayer schedule.")
        .supportedFamilies([
            .systemSmall, 
            .systemMedium, 
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
