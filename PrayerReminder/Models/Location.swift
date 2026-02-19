//
//  Location.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation

/// Represents a geographic location for prayer time calculations
struct Location: Codable, Equatable {
    // MARK: - Properties
    
    /// Latitude coordinate
    var latitude: Double
    
    /// Longitude coordinate
    var longitude: Double
    
    /// City name (e.g., "New York")
    var city: String
    
    /// Country name (e.g., "United States")
    var country: String
    
    /// Whether this location was manually selected (true) or GPS-detected (false)
    var isManual: Bool
    
    // MARK: - Initialization
    
    init(
        latitude: Double,
        longitude: Double,
        city: String,
        country: String = "",
        isManual: Bool = false
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.country = country
        self.isManual = isManual
    }
    
    // MARK: - Computed Properties
    
    /// Returns a formatted display string (e.g., "New York, United States")
    var displayName: String {
        if country.isEmpty {
            return city
        }
        return "\(city), \(country)"
    }
    
    /// Returns coordinate string for display (e.g., "40.7128°N, 74.0060°W")
    var coordinateString: String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"
        
        return String(format: "%.4f°%@, %.4f°%@",
                     abs(latitude), latDirection,
                     abs(longitude), lonDirection)
    }
    
    // MARK: - Distance Calculation
    
    /// Calculates the distance in kilometers between this location and another
    func distance(to other: Location) -> Double {
        let earthRadius = 6371.0 // Earth's radius in kilometers
        
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let lon2 = other.longitude * .pi / 180
        
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1) * cos(lat2) *
                sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    /// Checks if the location has changed significantly (more than 50km)
    func hasSignificantChange(from other: Location) -> Bool {
        return distance(to: other) > 50.0
    }
}

// MARK: - Sample Locations

extension Location {
    /// Cupertino, CA (default iOS Simulator location)
    static let cupertino = Location(
        latitude: 37.3230,
        longitude: -122.0322,
        city: "Cupertino",
        country: "United States"
    )
    
    /// New York City
    static let newYork = Location(
        latitude: 40.7128,
        longitude: -74.0060,
        city: "New York",
        country: "United States"
    )
    
    /// Mecca, Saudi Arabia
    static let mecca = Location(
        latitude: 21.4225,
        longitude: 39.8262,
        city: "Mecca",
        country: "Saudi Arabia"
    )
}
