//
//  OnboardingContainerView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI
import SwiftData

/// Container view that manages the onboarding flow
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var notificationService: NotificationService
    
    @Binding var isComplete: Bool
    
    @State private var isReady = false
    @State private var viewModel: OnboardingViewModel?
    
    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()
            
            if let viewModel = viewModel {
                OnboardingContentView(
                    viewModel: viewModel,
                    isComplete: $isComplete
                )
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(
                    locationService: locationService,
                    notificationService: notificationService,
                    modelContext: modelContext
                )
            }
        }
    }
}

/// Inner view that observes the view model
private struct OnboardingContentView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Binding var isComplete: Bool
    
    var body: some View {
        TabView(selection: $viewModel.currentStep) {
            WelcomeView(viewModel: viewModel)
                .tag(0)
            
            NameInputView(viewModel: viewModel)
                .tag(1)
            
            LocationSetupView(viewModel: viewModel)
                .tag(2)
            
            NotificationPermissionView(
                viewModel: viewModel,
                isComplete: $isComplete
            )
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentStep)
    }
}
