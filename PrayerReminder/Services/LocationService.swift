//
//  LocationService.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation
import CoreLocation
import Combine

/// Service for managing user location and GPS
@MainActor
class LocationService: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentLocation: Location?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: LocationError?
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Management
    
    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Location Fetching
    
    /// Get current location (async)
    func getCurrentLocation() async throws -> Location {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Check authorization status
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        // Get CLLocation
        let clLocation = try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
        
        print("📍 Got coordinates: \(clLocation.coordinate.latitude), \(clLocation.coordinate.longitude)")
        
        // Geocode to get city name
        let city = await geocodeLocation(clLocation.coordinate)
        
        let location = Location(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude,
            city: city.city,
            country: city.country,
            isManual: false
        )
        
        currentLocation = location
        return location
    }
    
    /// Start monitoring significant location changes
    func startMonitoringLocationChanges() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            print("⚠️ Cannot monitor location - not authorized")
            return
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
        print("📍 Started monitoring significant location changes")
    }
    
    /// Stop monitoring location changes
    func stopMonitoringLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
        print("🛑 Stopped monitoring location changes")
    }
    
    // MARK: - Geocoding
    
    /// Reverse geocode coordinates to city and country name
    private func geocodeLocation(_ coordinate: CLLocationCoordinate2D) async -> (city: String, country: String) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                let city = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                let country = placemark.country ?? ""
                
                print("🏙️ Geocoded to: \(city), \(country)")
                return (city, country)
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        return ("Unknown Location", "")
    }
    
    /// Geocode city name to coordinates (for manual location entry)
    func geocodeCity(_ cityName: String) async throws -> Location {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(cityName)
            
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                throw LocationError.geocodingFailed
            }
            
            let city = placemark.locality ?? placemark.administrativeArea ?? cityName
            let country = placemark.country ?? ""
            
            return Location(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                city: city,
                country: country,
                isManual: true
            )
        } catch {
            throw LocationError.geocodingFailed
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            print("📍 Location authorization changed to: \(authorizationStatus.rawValue)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        Task { @MainActor in
            self.error = .unknown
            locationContinuation?.resume(throwing: LocationError.unknown)
            locationContinuation = nil
        }
    }
}

// MARK: - Location Error

enum LocationError: LocalizedError {
    case permissionDenied
    case geocodingFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .geocodingFailed:
            return "Could not find the specified location. Please try a different city name."
        case .unknown:
            return "An unknown error occurred while getting your location."
        }
    }
}
