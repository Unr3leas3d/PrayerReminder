//
//  LocationPickerView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// View for selecting or updating user location
struct LocationPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationService()
    
    let settings: UserSettings
    
    @State private var isLoadingGPS = false
    @State private var manualCityName = ""
    @State private var error: String?
    @State private var tempLocation: Location?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: Constants.Spacing.large) {
                    // Current location display
                    VStack(spacing: 12) {
                        Text("Current Location")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.adaptiveTextSecondary)
                        
                        Text(tempLocation?.displayName ?? settings.location.displayName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.adaptiveText)
                            .multilineTextAlignment(.center)
                        
                        Text(tempLocation?.coordinateString ?? settings.location.coordinateString)
                            .font(.system(size: 14))
                            .foregroundColor(.adaptiveTextSecondary)
                    }
                    .padding()
                    .background(Color.adaptivePrimary.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // GPS Location
                    Button(action: {
                        Task {
                            isLoadingGPS = true
                            error = nil
                            
                            do {
                                let location = try await locationService.getCurrentLocation()
                                tempLocation = location
                                isLoadingGPS = false
                            } catch {
                                isLoadingGPS = false
                                self.error = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            if isLoadingGPS {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "location.fill")
                                Text("Use Current Location")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.adaptivePrimary)
                        .cornerRadius(Constants.CornerRadius.medium)
                    }
                    .padding(.horizontal)
                    .disabled(isLoadingGPS)
                    
                    // Manual entry
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Or enter city manually")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.adaptiveTextSecondary)
                            .padding(.horizontal)
                        
                        HStack {
                            TextField("City name", text: $manualCityName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.adaptivePrimary.opacity(0.1))
                                .cornerRadius(Constants.CornerRadius.medium)
                            
                            Button(action: {
                                Task {
                                    error = nil
                                    
                                    do {
                                        let location = try await locationService.geocodeCity(manualCityName)
                                        tempLocation = location
                                    } catch {
                                        self.error = "Could not find city"
                                    }
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.adaptivePrimary)
                                    .cornerRadius(Constants.CornerRadius.medium)
                            }
                            .disabled(manualCityName.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    
                    if let error = error {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Update Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let tempLocation = tempLocation {
                            settings.location = tempLocation
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                    .disabled(tempLocation == nil)
                }
            }
        }
    }
}
