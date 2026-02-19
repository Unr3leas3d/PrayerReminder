//
//  PrayerReminderApp.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI
import SwiftData

@main
struct PrayerReminderApp: App {
    // MARK: - SwiftData Model Container
    
    let modelContainer: ModelContainer
    
    // MARK: - State
    
    @AppStorage(Constants.Defaults.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @StateObject private var notificationService = NotificationService()
    @StateObject private var locationService = LocationService()
    @StateObject private var cloudSyncService = CloudSyncService()
    
    // MARK: - Initialization
    
    init() {
        // Initialize SwiftData model container
        do {
            let schema = Schema([
                PrayerTime.self,
                UserSettings.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none // We use CloudKit separately for settings
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ SwiftData model container initialized")
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    // Main app
                    MainContentView()
                        .environmentObject(notificationService)
                        .environmentObject(locationService)
                        .environmentObject(cloudSyncService)
                } else {
                    // Onboarding flow
                    OnboardingContainerView(isComplete: $hasCompletedOnboarding)
                        .environmentObject(notificationService)
                        .environmentObject(locationService)
                        .environmentObject(cloudSyncService)
                }
            }
            .modelContainer(modelContainer)
        }
    }
}

// MARK: - Main Content View

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var cloudSyncService: CloudSyncService
    
    @State private var viewModel: PrayerViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                MainTabContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = PrayerViewModel(modelContext: modelContext)
                vm.setServices(notification: notificationService, cloudSync: cloudSyncService)
                viewModel = vm
            }
        }
    }
}

/// Inner view that properly observes PrayerViewModel's @Published properties
private struct MainTabContent: View {
    @ObservedObject var viewModel: PrayerViewModel
    
    var body: some View {
        TabView {
            MainPrayerView(viewModel: viewModel)
                .tabItem {
                    Label("Prayer", systemImage: "moon.stars.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.adaptivePrimary)
    }
}
