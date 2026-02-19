//
//  NotificationPermissionView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// Notification permission screen - final step of onboarding
struct NotificationPermissionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject private var notificationService: NotificationService
    @Binding var isComplete: Bool
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.adaptivePrimary)
            
            Text("Enable Prayer Reminders")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.adaptiveText)
                .multilineTextAlignment(.center)
            
            Text("Get notified at each prayer time so you never miss a prayer")
                .font(.system(size: 16))
                .foregroundColor(.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.large)
            
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "clock.fill",
                    title: "Timely Reminders",
                    description: "Notifications at exact prayer times"
                )
                
                FeatureRow(
                    icon: "person.fill",
                    title: "Personalized",
                    description: "Messages tailored with your name"
                )
                
                FeatureRow(
                    icon: "gearshape.fill",
                    title: "Customizable",
                    description: "Choose which prayers to be reminded of"
                )
            }
            .padding(.horizontal, Constants.Spacing.large)
            
            Spacer()
            
            Button(action: {
                Task {
                    isRequesting = true
                    let granted = await notificationService.requestPermission()
                    isRequesting = false
                    
                    if granted {
                        await completeOnboarding()
                    }
                }
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "bell.fill")
                        Text("Allow Notifications")
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.adaptivePrimary)
                .cornerRadius(Constants.CornerRadius.medium)
            }
            .padding(.horizontal, Constants.Spacing.large)
            .disabled(isRequesting)
            
            Button(action: {
                Task {
                    await completeOnboarding()
                }
            }) {
                Text("Skip for now")
                    .font(.system(size: 16))
                    .foregroundColor(.adaptivePrimary)
            }
            .padding(.top, 8)
            
            Button(action: {
                viewModel.previousStep()
            }) {
                Text("Back")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.adaptivePrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptivePrimary.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
            }
            .padding(.horizontal, Constants.Spacing.large)
            .padding(.bottom, Constants.Spacing.extraLarge)
            .padding(.top, Constants.Spacing.medium)
        }
        .padding()
    }
    
    private func completeOnboarding() async {
        let success = await viewModel.completeOnboarding()
        if success {
            withAnimation {
                isComplete = true
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.adaptivePrimary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.adaptiveText)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.adaptiveTextSecondary)
            }
        }
    }
}
