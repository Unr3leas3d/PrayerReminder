//
//  Color+Theme.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

extension Color {
    // MARK: - Light Mode Colors
    
    /// Primary green color for Islamic aesthetic (light mode)
    static let primaryGreen = Color(hex: "#2D6A4F")
    
    /// Accent gold color for highlights (light mode)
    static let accentGold = Color(hex: "#D4AF37")
    
    /// Background color (light mode)
    static let backgroundLight = Color(hex: "#F8F9FA")
    
    /// Primary text color (light mode)
    static let textPrimary = Color(hex: "#212529")
    
    /// Secondary text color (light mode)
    static let textSecondary = Color(hex: "#6C757D")
    
    // MARK: - Dark Mode Colors
    
    /// Primary green color for Islamic aesthetic (dark mode)
    static let primaryGreenDark = Color(hex: "#52B788")
    
    /// Accent gold color for highlights (dark mode)
    static let accentGoldDark = Color(hex: "#FFD700")
    
    /// Background color (dark mode)
    static let backgroundDark = Color(hex: "#1A1D29")
    
    /// Primary text color (dark mode)
    static let textPrimaryDark = Color(hex: "#E9ECEF")
    
    /// Secondary text color (dark mode)
    static let textSecondaryDark = Color(hex: "#ADB5BD")
    
    // MARK: - Adaptive Colors (automatically switch based on color scheme)
    
    static var adaptiveBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.backgroundDark) :
                UIColor(Color.backgroundLight)
        })
    }
    
    static var adaptivePrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.primaryGreenDark) :
                UIColor(Color.primaryGreen)
        })
    }
    
    static var adaptiveAccent: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.accentGoldDark) :
                UIColor(Color.accentGold)
        })
    }
    
    static var adaptiveText: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.textPrimaryDark) :
                UIColor(Color.textPrimary)
        })
    }
    
    static var adaptiveTextSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.textSecondaryDark) :
                UIColor(Color.textSecondary)
        })
    }
    
    // MARK: - Hex Initializer
    
    /// Create a Color from hex string (e.g., "#FF5733")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
