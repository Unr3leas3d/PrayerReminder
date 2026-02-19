//
//  PrayerTimeService.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import SwiftData

/// Service for fetching and caching prayer times from Aladhan API
@MainActor
class PrayerTimeService: ObservableObject {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let baseURL = "https://api.aladhan.com/v1/timings"
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Fetch prayer times for a specific date and location
    /// - Parameters:
    ///   - date: The date to fetch prayer times for
    ///   - location: The location (latitude, longitude)
    ///   - method: The calculation method to use
    /// - Returns: PrayerTime object with all prayer times
    func fetchPrayerTimes(
        for date: Date = Date(),
        location: Location,
        method: CalculationMethod
    ) async throws -> PrayerTime {
        // Check cache first
        if let cached = getCachedPrayerTimes(for: date, location: location) {
            print("📦 Using cached prayer times for \(date)")
            return cached
        }
        
        print("🌐 Fetching prayer times from API for \(location.city)")
        
        // Build API URL
        let timestamp = Int(date.timeIntervalSince1970)
        var components = URLComponents(string: "\(baseURL)/\(timestamp)")!
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "method", value: String(method.apiValue))
        ]
        
        guard let url = components.url else {
            throw PrayerTimeError.invalidURL
        }
        
        // Make network request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PrayerTimeError.networkError
        }
        
        // Parse response
        let prayerTime = try parsePrayerTimeResponse(data, date: date, location: location)
        
        // Save to cache
        saveToCache(prayerTime)
        
        print("✅ Successfully fetched prayer times for \(location.city)")
        return prayerTime
    }
    
    /// Get cached prayer times for a specific date
    func getCachedPrayerTimes(for date: Date, location: Location? = nil) -> PrayerTime? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<PrayerTime>(
            predicate: #Predicate { prayerTime in
                prayerTime.date >= startOfDay && prayerTime.date < endOfDay
            }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            
            // If location specified, filter by location
            if let location = location {
                return results.first { $0.location == location }
            }
            
            return results.first
        } catch {
            print("Error fetching cached prayer times: \(error)")
            return nil
        }
    }
    
    /// Fetch prayer times for a date range (for week/month views)
    func fetchPrayerTimesRange(
        from startDate: Date,
        to endDate: Date,
        location: Location,
        method: CalculationMethod
    ) async throws -> [PrayerTime] {
        var prayerTimes: [PrayerTime] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            let prayerTime = try await fetchPrayerTimes(
                for: currentDate,
                location: location,
                method: method
            )
            prayerTimes.append(prayerTime)
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return prayerTimes
    }
    
    /// Clear old cached prayer times (older than 30 days)
    func clearOldCache() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        
        let descriptor = FetchDescriptor<PrayerTime>(
            predicate: #Predicate { $0.date < thirtyDaysAgo }
        )
        
        do {
            let oldPrayerTimes = try modelContext.fetch(descriptor)
            for prayerTime in oldPrayerTimes {
                modelContext.delete(prayerTime)
            }
            try modelContext.save()
            print("🗑️ Cleared \(oldPrayerTimes.count) old prayer time entries")
        } catch {
            print("Error clearing old cache: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func parsePrayerTimeResponse(
        _ data: Data,
        date: Date,
        location: Location
    ) throws -> PrayerTime {
        let decoder = JSONDecoder()
        let response = try decoder.decode(AladhanResponse.self, from: data)
        
        let timings = response.data.timings
        let hijri = response.data.date.hijri
        
        // Parse prayer times
        let fajr = parseTime(timings.fajr, date: date)
        let dhuhr = parseTime(timings.dhuhr, date: date)
        let asr = parseTime(timings.asr, date: date)
        let maghrib = parseTime(timings.maghrib, date: date)
        let isha = parseTime(timings.isha, date: date)
        
        // Format Hijri date
        let hijriDate = "\(hijri.day) \(hijri.month.en) \(hijri.year)"
        
        return PrayerTime(
            date: date,
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            hijriDate: hijriDate,
            location: location
        )
    }
    
    private func parseTime(_ timeString: String, date: Date) -> Date {
        // Time format from API: "HH:mm" or "HH:mm (timezone)"
        let cleanTime = timeString.components(separatedBy: " ").first ?? timeString
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        if let time = formatter.date(from: cleanTime) {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            
            return calendar.date(from: combined) ?? date
        }
        
        return date
    }
    
    private func saveToCache(_ prayerTime: PrayerTime) {
        modelContext.insert(prayerTime)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving prayer time to cache: \(error)")
        }
    }
}

// MARK: - API Response Models

private struct AladhanResponse: Codable {
    let data: AladhanData
}

private struct AladhanData: Codable {
    let timings: AladhanTimings
    let date: AladhanDate
}

private struct AladhanTimings: Codable {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    
    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
    }
}

private struct AladhanDate: Codable {
    let hijri: HijriDate
}

private struct HijriDate: Codable {
    let day: String
    let month: HijriMonth
    let year: String
}

private struct HijriMonth: Codable {
    let en: String
}

// MARK: - Error Types

enum PrayerTimeError: LocalizedError {
    case invalidURL
    case networkError
    case parsingError
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network request failed"
        case .parsingError:
            return "Failed to parse prayer times"
        case .notFound:
            return "Prayer times not found"
        }
    }
}
