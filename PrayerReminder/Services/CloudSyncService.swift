//
//  CloudSyncService.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import CloudKit
import SwiftData

/// Service for syncing user settings to iCloud via CloudKit
@MainActor
class CloudSyncService: ObservableObject {
    // MARK: - Properties
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncEnabled = false // Default to false for safety
    
    private var container: CKContainer? {
        guard syncEnabled else { return nil }
        // Attempt to access default container only if enabled
        return CKContainer.default()
    }
    private let recordType = "UserSettings"
    private let debounceInterval: TimeInterval = 2.0
    private var syncTask: Task<Void, Never>?
    private var _cloudKitAvailable: Bool?
    
    // MARK: - Public Methods
    
    /// Sync settings to iCloud
    func syncSettings(_ settings: UserSettings) async {
        guard syncEnabled else {
            print("⏸️ iCloud sync is disabled")
            return
        }
        
        // Cancel existing sync task (debounce)
        syncTask?.cancel()
        
        syncTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await performSync(settings)
        }
        
        await syncTask?.value
    }
    
    /// Fetch settings from iCloud
    func fetchSettings() async throws -> UserSettings? {
        guard syncEnabled else {
            print("⏸️ iCloud sync is disabled")
            return nil
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        guard let container = container else {
            print("⚠️ CloudKit container not available")
            return nil
        }
        
        let database = container.privateCloudDatabase
        
        // Query for settings record
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        do {
            let results = try await database.records(matching: query)
            
            guard let (_, result) = results.matchResults.first else {
                print("ℹ️ No settings found in iCloud")
                return nil
            }
            
            let record = try result.get()
            let settings = convertRecordToSettings(record)
            
            lastSyncDate = Date()
            print("☁️ Successfully fetched settings from iCloud")
            
            return settings
        } catch {
            print("Error fetching from iCloud: \(error)")
            throw CloudSyncError.fetchFailed
        }
    }
    
    /// Check if iCloud is available
    func checkiCloudStatus() async -> Bool {
        do {
            guard let container = container else {
                syncEnabled = false
                return false
            }
            let status = try await container.accountStatus()
            let isAvailable = status == .available
            
            if !isAvailable {
                print("⚠️ iCloud is not available")
                syncEnabled = false
            }
            
            return isAvailable
        } catch {
            print("Error checking iCloud status: \(error)")
            syncEnabled = false
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func performSync(_ settings: UserSettings) async {
        isSyncing = true
        defer { isSyncing = false }
        
        guard let container = container else {
            print("⚠️ CloudKit container not available for sync")
            return
        }
        
        let database = container.privateCloudDatabase
        
        do {
            // Check if record already exists
            let existingRecord = try await fetchExistingRecord()
            
            let record: CKRecord
            if let existing = existingRecord {
                record = existing
            } else {
                record = CKRecord(recordType: recordType)
            }
            
            // Update record with settings
            convertSettingsToRecord(settings, record: record)
            
            // Save to CloudKit
            try await database.save(record)
            
            lastSyncDate = Date()
            settings.lastSyncDate = lastSyncDate
            
            print("☁️ Successfully synced settings to iCloud")
        } catch {
            print("Error syncing to iCloud: \(error)")
        }
    }
    
    private func fetchExistingRecord() async throws -> CKRecord? {
        guard let container = container else { return nil }
        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        
        let results = try await database.records(matching: query)
        
        guard let (_, result) = results.matchResults.first else {
            return nil
        }
        
        return try result.get()
    }
    
    private func convertSettingsToRecord(_ settings: UserSettings, record: CKRecord) {
        record["userName"] = settings.userName
        record["latitude"] = settings.location.latitude
        record["longitude"] = settings.location.longitude
        record["city"] = settings.location.city
        record["country"] = settings.location.country
        record["isManualLocation"] = settings.location.isManual
        record["calculationMethod"] = settings.calculationMethodRawValue
        record["showGregorianDate"] = settings.showGregorianDate
        record["theme"] = settings.themeRawValue
        record["autoUpdateLocation"] = settings.autoUpdateLocation
        
        // Encode dictionaries as JSON strings
        if let enabledPrayersData = try? JSONEncoder().encode(settings.enabledPrayers),
           let enabledPrayersString = String(data: enabledPrayersData, encoding: .utf8) {
            record["enabledPrayers"] = enabledPrayersString
        }
        
        if let notificationTimingsData = try? JSONEncoder().encode(settings.notificationTimings),
           let notificationTimingsString = String(data: notificationTimingsData, encoding: .utf8) {
            record["notificationTimings"] = notificationTimingsString
        }
    }
    
    private func convertRecordToSettings(_ record: CKRecord) -> UserSettings {
        let userName = record["userName"] as? String ?? ""
        let latitude = record["latitude"] as? Double ?? 0.0
        let longitude = record["longitude"] as? Double ?? 0.0
        let city = record["city"] as? String ?? "Unknown"
        let country = record["country"] as? String ?? ""
        let isManual = record["isManualLocation"] as? Bool ?? false
        
        let location = Location(
            latitude: latitude,
            longitude: longitude,
            city: city,
            country: country,
            isManual: isManual
        )
        
        let calcMethodRaw = record["calculationMethod"] as? Int ?? CalculationMethod.muslimWorldLeague.rawValue
        let calculationMethod = CalculationMethod(rawValue: calcMethodRaw) ?? .muslimWorldLeague
        
        let showGregorian = record["showGregorianDate"] as? Bool ?? true
        let themeRaw = record["theme"] as? Int ?? AppTheme.system.rawValue
        let theme = AppTheme(rawValue: themeRaw) ?? .system
        let autoUpdate = record["autoUpdateLocation"] as? Bool ?? false
        
        // Decode dictionaries from JSON strings
        var enabledPrayers: [String: Bool]?
        if let enabledPrayersString = record["enabledPrayers"] as? String,
           let data = enabledPrayersString.data(using: .utf8) {
            enabledPrayers = try? JSONDecoder().decode([String: Bool].self, from: data)
        }
        
        var notificationTimings: [String: Int]?
        if let notificationTimingsString = record["notificationTimings"] as? String,
           let data = notificationTimingsString.data(using: .utf8) {
            notificationTimings = try? JSONDecoder().decode([String: Int].self, from: data)
        }
        
        return UserSettings(
            userName: userName,
            location: location,
            calculationMethod: calculationMethod,
            enabledPrayers: enabledPrayers,
            notificationTimings: notificationTimings,
            showGregorianDate: showGregorian,
            theme: theme,
            autoUpdateLocation: autoUpdate
        )
    }
}

// MARK: - Cloud Sync Error

enum CloudSyncError: LocalizedError {
    case fetchFailed
    case saveFailed
    case notAvailable
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch settings from iCloud"
        case .saveFailed:
            return "Failed to save settings to iCloud"
        case .notAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        }
    }
}
