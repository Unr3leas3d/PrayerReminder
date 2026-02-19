//
//  WelcomeView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// Welcome screen - first step of onboarding
struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Spacer()
            
            // Crescent moon icon
            CrescentMoonIcon(size: 100)
                .foregroundColor(.adaptivePrimary)
            
            Text("Prayer Reminder")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.adaptiveText)
            
            Text("Stay connected to your daily prayers with a clean, focused reminder app")
                .font(.system(size: 18))
                .foregroundColor(.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.large)
            
            Spacer()
            
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptivePrimary)
                    .cornerRadius(Constants.CornerRadius.medium)
            }
            .padding(.horizontal, Constants.Spacing.large)
            .padding(.bottom, Constants.Spacing.extraLarge)
        }
        .padding()
    }
}

// MARK: - Crescent Moon Icon

struct CrescentMoonIcon: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.adaptivePrimary.opacity(0.2))
                .frame(width: size, height: size)
            
            Image(systemName: "moon.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.5, height: size * 0.5)
        }
    }
}
