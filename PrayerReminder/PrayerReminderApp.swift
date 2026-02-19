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
                cloudKitDatabase: .none
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
            AppRootView(
                hasCompletedOnboarding: $hasCompletedOnboarding,
                notificationService: notificationService,
                locationService: locationService
            )
            .modelContainer(modelContainer)
        }
    }
}

// MARK: - App Root View

struct AppRootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var locationService: LocationService
    
    @Query private var settingsQuery: [UserSettings]
    
    var theme: ColorScheme? {
        guard let settings = settingsQuery.first else { return nil }
        switch settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                // Main app
                MainContentView()
                    .environmentObject(notificationService)
                    .environmentObject(locationService)
            } else {
                // Onboarding flow
                OnboardingContainerView(isComplete: $hasCompletedOnboarding)
                    .environmentObject(notificationService)
                    .environmentObject(locationService)
            }
        }
        .preferredColorScheme(theme)
    }
}

// MARK: - Main Content View

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService
    
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
                vm.setServices(notification: notificationService)
                viewModel = vm
            }
        }
    }
}

/// Inner view using TabView for main navigation
private struct MainTabContent: View {
    @ObservedObject var viewModel: PrayerViewModel
    @EnvironmentObject private var notificationService: NotificationService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                MainPrayerView(viewModel: viewModel)
            }
            .tabItem {
                Label("Home", systemImage: "moon.stars.fill")
            }
            .tag(0)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(1)
        }
        .environmentObject(viewModel)
        .accentColor(.adaptivePrimary)
        .onChange(of: notificationService.shouldNavigateToHome) { _, shouldNavigate in
            if shouldNavigate {
                selectedTab = 0
                notificationService.shouldNavigateToHome = false
            }
        }
    }
}
