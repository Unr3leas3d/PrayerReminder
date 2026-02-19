//
//  CalculationMethodPickerView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// View for selecting prayer time calculation method
struct CalculationMethodPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let settings: UserSettings
    @State private var selectedMethod: CalculationMethod
    
    init(settings: UserSettings) {
        self.settings = settings
        _selectedMethod = State(initialValue: settings.calculationMethod)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                List {
                    ForEach(CalculationMethod.allCases) { method in
                        Button(action: {
                            selectedMethod = method
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.adaptiveText)
                                    
                                    Text(method.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.adaptivePrimary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Calculation Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        settings.calculationMethod = selectedMethod
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(selectedMethod == settings.calculationMethod)
                }
            }
        }
    }
}
