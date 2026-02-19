//
//  NotificationSettingsView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// View for configuring prayer notifications
struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: PrayerViewModel
    @EnvironmentObject private var notificationService: NotificationService
    
    let settings: UserSettings
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                List {
                    Section {
                        if settings.enabledPrayersCount > 0 {
                            if let todayTimes = viewModel.todayPrayerTimes {
                                ForEach(Constants.prayerNames, id: \.self) { prayerName in
                                    if settings.isPrayerEnabled(prayerName),
                                       let prayerTime = todayTimes.time(for: prayerName) {
                                        
                                        let minutesBefore = settings.notificationTiming(for: prayerName)
                                        let notificationTime = Calendar.current.date(
                                            byAdding: .minute,
                                            value: -minutesBefore,
                                            to: prayerTime
                                        ) ?? prayerTime
                                        
                                        HStack {
                                            Text(prayerName)
                                                .fontWeight(.medium)
                                                .foregroundColor(.adaptiveText)
                                            Spacer()
                                            Text(notificationTime.formatted(date: .omitted, time: .shortened))
                                                .foregroundColor(.adaptiveTextSecondary)
                                        }
                                    }
                                }
                            } else {
                                Text("Loading schedule...")
                                    .font(.caption)
                                    .foregroundColor(.adaptiveTextSecondary)
                            }
                        } else {
                            Text("No notifications scheduled")
                                .font(.system(size: 14))
                                .foregroundColor(.adaptiveTextSecondary)
                        }
                    } header: {
                        Text("Prayer reminders:")
                    }
                    
                    ForEach(Constants.prayerNames, id: \.self) { prayerName in
                        Section {
                            // Enable/Disable toggle
                            Toggle(isOn: Binding(
                                get: { settings.isPrayerEnabled(prayerName) },
                                set: { newValue in
                                    settings.enabledPrayers[prayerName] = newValue
                                    Task {
                                        await viewModel.updateSettings(settings)
                                    }
                                }
                            )) {
                                Text("Enable \(prayerName) Notification")
                                    .foregroundColor(.adaptiveText)
                            }
                            .tint(.adaptivePrimary)
                            
                            // Timing picker (only if enabled)
                            if settings.isPrayerEnabled(prayerName) {
                                Picker("Notify", selection: Binding(
                                    get: { settings.notificationTiming(for: prayerName) },
                                    set: { newValue in
                                        settings.notificationTimings[prayerName] = newValue
                                        Task {
                                            await viewModel.updateSettings(settings)
                                        }
                                    }
                                )) {
                                    ForEach(Constants.notificationTimingOptions, id: \.self) { minutes in
                                        Text(Constants.notificationTimingDisplayName(for: minutes))
                                            .tag(minutes)
                                    }
                                }
                                .tint(.adaptivePrimary)
                            }
                        } header: {
                            Text(prayerName)
                        }
                    }
                    
                    /*
                    // Test Notification Section
                    Section {
                        Button(action: {
                            notificationService.scheduleTestNotification()
                        }) {
                            HStack {
                                Text("Send Test Notification")
                                    .foregroundColor(.adaptiveText)
                                Spacer()
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.adaptivePrimary)
                            }
                        }
                    } header: {
                        Text("Test")
                    } footer: {
                        Text("Sends a notification in 5 seconds to verify permissions and sound.")
                            .font(.caption)
                            .foregroundColor(.adaptiveTextSecondary)
                    }
                    */
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
