//
//  LocationSetupView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// Location setup screen - third step of onboarding
struct LocationSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showManualEntry = false
    @State private var manualCityName = ""
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Spacer()
            
            Image(systemName: "location.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.adaptivePrimary)
            
            Text("Set Your Location")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.adaptiveText)
                .multilineTextAlignment(.center)
            
            Text("We need your location to calculate accurate prayer times")
                .font(.system(size: 16))
                .foregroundColor(.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.large)
            
            Spacer()
                .frame(height: 40)
            
            if let location = viewModel.selectedLocation {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text(location.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.adaptiveText)
                    
                    Text(location.coordinateString)
                        .font(.system(size: 14))
                        .foregroundColor(.adaptiveTextSecondary)
                }
                .padding()
                .background(Color.adaptivePrimary.opacity(0.1))
                .cornerRadius(Constants.CornerRadius.medium)
                .padding(.horizontal, Constants.Spacing.large)
            } else if viewModel.isLoadingLocation {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            }
            
            if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, Constants.Spacing.large)
            }
            
            Spacer()
            
            if !showManualEntry {
                Button(action: {
                    Task {
                        await viewModel.requestLocation()
                    }
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use Current Location")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptivePrimary)
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                .padding(.horizontal, Constants.Spacing.large)
                .disabled(viewModel.isLoadingLocation)
                
                Button(action: {
                    showManualEntry = true
                }) {
                    Text("Or enter city manually")
                        .font(.system(size: 16))
                        .foregroundColor(.adaptivePrimary)
                }
                .padding(.top, 8)
            } else {
                HStack {
                    TextField("Enter city name", text: $manualCityName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.adaptivePrimary.opacity(0.1))
                        .cornerRadius(Constants.CornerRadius.medium)
                    
                    Button(action: {
                        Task {
                            await viewModel.selectManualLocation(manualCityName)
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.adaptivePrimary)
                            .cornerRadius(Constants.CornerRadius.medium)
                    }
                    .disabled(manualCityName.isEmpty || viewModel.isLoadingLocation)
                }
                .padding(.horizontal, Constants.Spacing.large)
                
                Button(action: {
                    showManualEntry = false
                }) {
                    Text("Use GPS instead")
                        .font(.system(size: 16))
                        .foregroundColor(.adaptivePrimary)
                }
                .padding(.top, 8)
            }
            
            HStack {
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
                
                Button(action: {
                    viewModel.nextStep()
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canProceedFromLocation ? Color.adaptivePrimary : Color.gray)
                        .cornerRadius(Constants.CornerRadius.medium)
                }
                .disabled(!viewModel.canProceedFromLocation)
            }
            .padding(.horizontal, Constants.Spacing.large)
            .padding(.bottom, Constants.Spacing.extraLarge)
            .padding(.top, Constants.Spacing.medium)
        }
        .padding()
    }
}
