//
//  CalculationMethod.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import Foundation

/// Represents different Islamic prayer time calculation methods
enum CalculationMethod: Int, Codable, CaseIterable, Identifiable {
    // MARK: - Cases
    
    case muslimWorldLeague = 3
    case isna = 2
    case egyptian = 5
    case ummAlQura = 4
    case karachi = 1
    case tehran = 7
    case jafari = 0
    case gulf = 8
    case kuwait = 9
    case qatar = 10
    case singapore = 11
    case france = 12
    case turkey = 13
    case russia = 14
    
    // MARK: - Identifiable
    
    var id: Int { rawValue }
    
    // MARK: - Display Properties
    
    /// Human-readable name for the calculation method
    var displayName: String {
        switch self {
        case .muslimWorldLeague:
            return "Muslim World League"
        case .isna:
            return "Islamic Society of North America (ISNA)"
        case .egyptian:
            return "Egyptian General Authority of Survey"
        case .ummAlQura:
            return "Umm Al-Qura University, Makkah"
        case .karachi:
            return "University of Islamic Sciences, Karachi"
        case .tehran:
            return "Institute of Geophysics, University of Tehran"
        case .jafari:
            return "Shia Ithna-Ashari, Leva Institute, Qum"
        case .gulf:
            return "Gulf Region"
        case .kuwait:
            return "Kuwait"
        case .qatar:
            return "Qatar"
        case .singapore:
            return "Majlis Ugama Islam Singapura, Singapore"
        case .france:
            return "Union Organization Islamic de France"
        case .turkey:
            return "Diyanet İşleri Başkanlığı, Turkey"
        case .russia:
            return "Spiritual Administration of Muslims of Russia"
        }
    }
    
    /// Short name for display in compact spaces
    var shortName: String {
        switch self {
        case .muslimWorldLeague:
            return "MWL"
        case .isna:
            return "ISNA"
        case .egyptian:
            return "Egyptian"
        case .ummAlQura:
            return "Umm Al-Qura"
        case .karachi:
            return "Karachi"
        case .tehran:
            return "Tehran"
        case .jafari:
            return "Jafari"
        case .gulf:
            return "Gulf"
        case .kuwait:
            return "Kuwait"
        case .qatar:
            return "Qatar"
        case .singapore:
            return "Singapore"
        case .france:
            return "France"
        case .turkey:
            return "Turkey"
        case .russia:
            return "Russia"
        }
    }
    
    /// Description of the calculation method
    var description: String {
        switch self {
        case .muslimWorldLeague:
            return "Widely used globally, moderate approach"
        case .isna:
            return "Used primarily in North America"
        case .egyptian:
            return "Used in Egypt and surrounding regions"
        case .ummAlQura:
            return "Official method used in Saudi Arabia"
        case .karachi:
            return "Used in Pakistan and parts of South Asia"
        case .tehran:
            return "Used in Iran"
        case .jafari:
            return "Used by Shia communities"
        case .gulf:
            return "Used in Gulf countries"
        case .kuwait:
            return "Official method for Kuwait"
        case .qatar:
            return "Official method for Qatar"
        case .singapore:
            return "Official method for Singapore"
        case .france:
            return "Official method for France"
        case .turkey:
            return "Official method for Turkey"
        case .russia:
            return "Official method for Russia"
        }
    }
    
    /// The API value to send to Aladhan API
    var apiValue: Int {
        return rawValue
    }
    
    // MARK: - Default Method
    
    /// Default calculation method (Muslim World League)
    static var `default`: CalculationMethod {
        return .muslimWorldLeague
    }
    
    // MARK: - Regional Recommendations
    
    /// Returns recommended method based on country code
    static func recommended(forCountryCode code: String) -> CalculationMethod {
        switch code.uppercased() {
        case "US", "CA":
            return .isna
        case "EG":
            return .egyptian
        case "SA":
            return .ummAlQura
        case "PK", "IN", "BD":
            return .karachi
        case "IR":
            return .tehran
        case "KW":
            return .kuwait
        case "QA":
            return .qatar
        case "SG":
            return .singapore
        case "FR":
            return .france
        case "TR":
            return .turkey
        case "RU":
            return .russia
        case "AE", "OM", "BH":
            return .gulf
        default:
            return .muslimWorldLeague
        }
    }
}
