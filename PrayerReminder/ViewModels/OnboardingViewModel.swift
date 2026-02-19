//
//  OnboardingViewModel.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import SwiftUI
import SwiftData

/// View model for onboarding flow
@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentStep = 0
    @Published var userName = ""
    @Published var selectedLocation: Location?
    @Published var isLoadingLocation = false
    @Published var error: String?
    
    // MARK: - Services
    
    private let locationService: LocationService
    private let notificationService: NotificationService
    private let modelContext: ModelContext
    
    // MARK: - Computed Properties
    
    var canProceedFromName: Bool {
        !userName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var canProceedFromLocation: Bool {
        selectedLocation != nil
    }
    
    // MARK: - Initialization
    
    init(
        locationService: LocationService,
        notificationService: NotificationService,
        modelContext: ModelContext
    ) {
        self.locationService = locationService
        self.notificationService = notificationService
        self.modelContext = modelContext
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    func previousStep() {
        withAnimation {
            currentStep -= 1
        }
    }
    
    // MARK: - Location
    
    func requestLocation() async {
        isLoadingLocation = true
        error = nil
        
        do {
            let location = try await locationService.getCurrentLocation()
            selectedLocation = location
            isLoadingLocation = false
            print(" Got location: \(location.city)")
        } catch {
            isLoadingLocation = false
            self.error = error.localizedDescription
            print("Location error: \(error)")
        }
    }
    
    func selectManualLocation(_ cityName: String) async {
        isLoadingLocation = true
        error = nil
        
        do {
            let location = try await locationService.geocodeCity(cityName)
            selectedLocation = location
            isLoadingLocation = false
            print("📍 Manual location set: \(location.city)")
        } catch {
            isLoadingLocation = false
            self.error = "Could not find city. Please try again."
            print("Geocoding error: \(error)")
        }
    }
    
    // MARK: - Completion
    
    func completeOnboarding() async -> Bool {
        guard let location = selectedLocation else {
            error = "Please set your location"
            return false
        }
        
        // Create user settings
        let settings = UserSettings(
            userName: userName,
            location: location
        )
        
        modelContext.insert(settings)
        
        do {
            try modelContext.save()
            print("✅ Onboarding complete, settings saved")
            return true
        } catch {
            self.error = "Failed to save settings"
            print("Error saving settings: \(error)")
            return false
        }
    }
}
