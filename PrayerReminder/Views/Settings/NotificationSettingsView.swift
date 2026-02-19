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
    
    let settings: UserSettings
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                List {
                    Section {
                        Text("Choose which prayers you want to be notified for and when")
                            .font(.system(size: 14))
                            .foregroundColor(.adaptiveTextSecondary)
                    }
                    
                    ForEach(Constants.prayerNames, id: \.self) { prayerName in
                        Section {
                            // Enable/Disable toggle
                            Toggle(isOn: Binding(
                                get: { settings.isPrayerEnabled(prayerName) },
                                set: { newValue in
                                    settings.enabledPrayers[prayerName] = newValue
                                    try? modelContext.save()
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
                                        try? modelContext.save()
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
