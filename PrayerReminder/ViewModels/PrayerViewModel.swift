//
//  PrayerViewModel.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import SwiftData
import Combine

/// Main view model for prayer times and app state
@MainActor
class PrayerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var todayPrayerTimes: PrayerTime?
    @Published var weekPrayerTimes: [PrayerTime] = []
    @Published var monthPrayerTimes: [PrayerTime] = []
    @Published var settings: UserSettings?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentTime = Date()
    
    // MARK: - Services
    
    private var prayerTimeService: PrayerTimeService?
    private var notificationService: NotificationService?
    private var cloudSyncService: CloudSyncService?
    
    var modelContext: ModelContext?
    
    // MARK: - Timer
    
    private var timer: Timer?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
        
        if let modelContext = modelContext {
            self.prayerTimeService = PrayerTimeService(modelContext: modelContext)
            loadSettings()
        }
        
        // Start timer to update current time every minute
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        self.prayerTimeService = PrayerTimeService(modelContext: context)
        loadSettings()
    }
    
    func setServices(
        notification: NotificationService,
        cloudSync: CloudSyncService
    ) {
        self.notificationService = notification
        self.cloudSyncService = cloudSync
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<UserSettings>()
        
        do {
            let results = try modelContext.fetch(descriptor)
            
            if let existingSettings = results.first {
                settings = existingSettings
                print("✅ Loaded existing settings for \(existingSettings.userName)")
            } else {
                // Create default settings
                let defaultSettings = UserSettings()
                modelContext.insert(defaultSettings)
                try modelContext.save()
                settings = defaultSettings
                print("✅ Created default settings")
            }
            
            // Fetch today's prayer times
            Task {
                await refreshPrayerTimes()
            }
        } catch {
            print("Error loading settings: \(error)")
            self.error = "Failed to load settings"
        }
    }
    
    func updateSettings(_ newSettings: UserSettings) async {
        settings = newSettings
        
        do {
            try modelContext?.save()
            
            // Sync to iCloud
            if let cloudSync = cloudSyncService {
                await cloudSync.syncSettings(newSettings)
            }
            
            // Refresh prayer times if location or calculation method changed
            await refreshPrayerTimes()
            
            print("✅ Settings updated")
        } catch {
            print("Error updating settings: \(error)")
            self.error = "Failed to update settings"
        }
    }
    
    // MARK: - Prayer Times Management
    
    func refreshPrayerTimes() async {
        guard let settings = settings,
              let prayerTimeService = prayerTimeService else {
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            // Fetch today's prayer times
            let prayerTimes = try await prayerTimeService.fetchPrayerTimes(
                for: Date(),
                location: settings.location,
                method: settings.calculationMethod
            )
            
            todayPrayerTimes = prayerTimes
            
            // Schedule notifications
            if let notificationService = notificationService {
                await notificationService.scheduleNotifications(
                    for: prayerTimes,
                    settings: settings
                )
            }
            
            isLoading = false
            print("✅ Refreshed prayer times")
        } catch {
            isLoading = false
            self.error = "Failed to fetch prayer times: \(error.localizedDescription)"
            print("Error fetching prayer times: \(error)")
        }
    }
    
    func loadWeekPrayerTimes() async {
        guard let settings = settings,
              let prayerTimeService = prayerTimeService else {
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: 6, to: today)!
        
        do {
            weekPrayerTimes = try await prayerTimeService.fetchPrayerTimesRange(
                from: today,
                to: endDate,
                location: settings.location,
                method: settings.calculationMethod
            )
        } catch {
            print("Error loading week prayer times: \(error)")
        }
    }
    
    func loadMonthPrayerTimes() async {
        guard let settings = settings,
              let prayerTimeService = prayerTimeService else {
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let endDate = calendar.date(byAdding: .day, value: 29, to: today)!
        
        do {
            monthPrayerTimes = try await prayerTimeService.fetchPrayerTimesRange(
                from: today,
                to: endDate,
                location: settings.location,
                method: settings.calculationMethod
            )
        } catch {
            print("Error loading month prayer times: \(error)")
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = Date()
                
                // Check if we've crossed into a new day
                if let lastUpdate = self?.todayPrayerTimes?.date,
                   !Calendar.current.isDateInToday(lastUpdate) {
                    await self?.refreshPrayerTimes()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var currentPrayer: (name: String, time: Date)? {
        todayPrayerTimes?.currentPrayer
    }
    
    var nextPrayer: (name: String, time: Date)? {
        todayPrayerTimes?.nextPrayer
    }
    
    var hijriDate: String {
        todayPrayerTimes?.hijriDate ?? ""
    }
}
