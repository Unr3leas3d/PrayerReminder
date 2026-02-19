//
//  SettingsView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI
import SwiftData

/// Main settings view
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]
    @StateObject private var locationService = LocationService()
    @EnvironmentObject private var cloudSyncService: CloudSyncService
    
    @State private var showLocationPicker = false
    @State private var showCalculationMethodPicker = false
    @State private var showNotificationSettings = false
    
    private var settings: UserSettings? {
        settingsQuery.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                IslamicPatternView(opacity: 0.02)
                    .ignoresSafeArea()
                
                if let settings = settings {
                    List {
                        // Profile Section
                        Section {
                            HStack {
                                Text("Name")
                                    .foregroundColor(.adaptiveText)
                                Spacer()
                                Text(settings.userName)
                                    .foregroundColor(.adaptiveTextSecondary)
                            }
                            
                            Button(action: {
                                showLocationPicker = true
                            }) {
                                HStack {
                                    Text("Location")
                                        .foregroundColor(.adaptiveText)
                                    Spacer()
                                    Text(settings.location.displayName)
                                        .foregroundColor(.adaptiveTextSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                            }
                        } header: {
                            Text("Profile")
                        }
                        
                        // Prayer Settings
                        Section {
                            Button(action: {
                                showCalculationMethodPicker = true
                            }) {
                                HStack {
                                    Text("Calculation Method")
                                        .foregroundColor(.adaptiveText)
                                    Spacer()
                                    Text(settings.calculationMethod.shortName)
                                        .foregroundColor(.adaptiveTextSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                            }
                            
                            Button(action: {
                                showNotificationSettings = true
                            }) {
                                HStack {
                                    Text("Notification Settings")
                                        .foregroundColor(.adaptiveText)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                            }
                        } header: {
                            Text("Prayer Settings")
                        }
                        
                        // Display Settings
                        Section {
                            Toggle(isOn: Binding(
                                get: { settings.showGregorianDate },
                                set: { newValue in
                                    settings.showGregorianDate = newValue
                                    try? modelContext.save()
                                }
                            )) {
                                Text("Show Gregorian Date")
                                    .foregroundColor(.adaptiveText)
                            }
                            .tint(.adaptivePrimary)
                            
                            Picker("Theme", selection: Binding(
                                get: { settings.theme },
                                set: { newValue in
                                    settings.theme = newValue
                                    try? modelContext.save()
                                }
                            )) {
                                ForEach(AppTheme.allCases) { theme in
                                    Text(theme.displayName).tag(theme)
                                }
                            }
                            .tint(.adaptivePrimary)
                        } header: {
                            Text("Display")
                        }
                        
                        // Location Settings
                        Section {
                            let locService = locationService
                            Toggle(isOn: Binding(
                                get: { settings.autoUpdateLocation },
                                set: { newValue in
                                    settings.autoUpdateLocation = newValue
                                    try? modelContext.save()
                                    
                                    if newValue {
                                        locService.startMonitoringLocationChanges()
                                    } else {
                                        locService.stopMonitoringLocationChanges()
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Auto-Update Location")
                                        .foregroundColor(.adaptiveText)
                                    Text("Update prayer times when you travel")
                                        .font(.caption)
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                            }
                            .tint(.adaptivePrimary)
                        } header: {
                            Text("Location")
                        }
                        
                        // iCloud Sync Section
                        Section {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("iCloud Synchronization")
                                        .foregroundColor(.adaptiveText)
                                    Text(cloudSyncService.syncEnabled ? "Keep your settings in sync across devices" : "iCloud sync is currently disabled.")
                                        .font(.caption)
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $cloudSyncService.syncEnabled)
                                    .labelsHidden()
                                    .tint(.adaptivePrimary)
                            }
                            
                            if !cloudSyncService.syncEnabled {
                                Text("⚠️ CloudKit requires entitlements. Enable only if configured in Xcode.")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            
                            if cloudSyncService.syncEnabled {
                                Button(action: {
                                    Task {
                                        await cloudSyncService.syncSettings(settings)
                                    }
                                }) {
                                    HStack {
                                        Text("Sync Now")
                                            .foregroundColor(.adaptivePrimary)
                                        if cloudSyncService.isSyncing {
                                            Spacer()
                                            ProgressView()
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Cloud Sync")
                        }
                        
                        // About Section
                        Section {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.adaptiveText)
                                Spacer()
                                Text(Constants.appVersion)
                                    .foregroundColor(.adaptiveTextSecondary)
                            }
                            
                            if let lastSync = settings.lastSyncDate {
                                HStack {
                                    Text("Last iCloud Sync")
                                        .foregroundColor(.adaptiveText)
                                    Spacer()
                                    Text(lastSync.shortDateString)
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                            }
                        } header: {
                            Text("About")
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showLocationPicker) {
                if let settings = settings {
                    LocationPickerView(settings: settings)
                }
            }
            .sheet(isPresented: $showCalculationMethodPicker) {
                if let settings = settings {
                    CalculationMethodPickerView(settings: settings)
                }
            }
            .sheet(isPresented: $showNotificationSettings) {
                if let settings = settings {
                    NotificationSettingsView(settings: settings)
                }
            }
        }
    }
}
