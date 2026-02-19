//
//  NameInputView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// Name input screen - second step of onboarding
struct NameInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            Spacer()
            
            Text("What's your name?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.adaptiveText)
                .multilineTextAlignment(.center)
            
            Text("We'll use this to personalize your prayer reminders")
                .font(.system(size: 16))
                .foregroundColor(.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.large)
            
            Spacer()
                .frame(height: 40)
            
            TextField("Enter your name", text: $viewModel.userName)
                .font(.system(size: 24))
                .textFieldStyle(.plain)
                .padding()
                .background(Color.adaptivePrimary.opacity(0.1))
                .cornerRadius(Constants.CornerRadius.medium)
                .focused($isTextFieldFocused)
                .submitLabel(.continue)
                .onSubmit {
                    if viewModel.canProceedFromName {
                        viewModel.nextStep()
                    }
                }
                .padding(.horizontal, Constants.Spacing.large)
            
            Spacer()
            
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
                        .background(viewModel.canProceedFromName ? Color.adaptivePrimary : Color.gray)
                        .cornerRadius(Constants.CornerRadius.medium)
                }
                .disabled(!viewModel.canProceedFromName)
            }
            .padding(.horizontal, Constants.Spacing.large)
            .padding(.bottom, Constants.Spacing.extraLarge)
        }
        .padding()
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
