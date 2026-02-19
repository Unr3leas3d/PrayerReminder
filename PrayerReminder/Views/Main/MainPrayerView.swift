//
//  MainPrayerView.swift
//  PrayerReminder
//
//  Created on February 17, 2026.
//

import SwiftUI

/// Main prayer view showing current and next prayer
struct MainPrayerView: View {
    @ObservedObject var viewModel: PrayerViewModel
    @State private var showWeekView = false
    @State private var showMonthView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                IslamicPatternView(opacity: 0.04)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Header with greeting and dates
                        HeaderSection(viewModel: viewModel)
                        
                        // Current prayer (just passed)
                        if let current = viewModel.currentPrayer {
                            CurrentPrayerCard(
                                prayerName: current.name,
                                prayerTime: current.time
                            )
                        }
                        
                        // Next prayer with countdown
                        if let next = viewModel.nextPrayer {
                            NextPrayerCard(
                                prayerName: next.name,
                                prayerTime: next.time,
                                currentTime: viewModel.currentTime
                            )
                        } else {
                            // All prayers passed for today
                            AllPrayersCompletedCard()
                        }
                        
                        // Quick actions
                        QuickActionsRow(
                            showWeek: $showWeekView,
                            showMonth: $showMonthView
                        )
                        
                        // Today's prayer times list
                        if let prayerTimes = viewModel.todayPrayerTimes {
                            TodayPrayersList(prayerTimes: prayerTimes)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshPrayerTimes()
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .navigationTitle("Prayer Times")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showWeekView) {
                WeekPrayerTimesView(viewModel: viewModel)
            }
            .sheet(isPresented: $showMonthView) {
                MonthPrayerTimesView(viewModel: viewModel)
            }
            .task {
                if viewModel.todayPrayerTimes == nil {
                    await viewModel.refreshPrayerTimes()
                }
            }
        }
    }
}

// MARK: - Header Section

struct HeaderSection: View {
    @ObservedObject var viewModel: PrayerViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            if let settings = viewModel.settings {
                Text("\(Constants.randomGreeting()), \(settings.userName)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.adaptiveText)
            }
            
            Text(Date().fullDateString)
                .font(.system(size: 16))
                .foregroundColor(.adaptiveTextSecondary)
            
            if !viewModel.hijriDate.isEmpty {
                Text(viewModel.hijriDate)
                    .font(.system(size: 14))
                    .foregroundColor(.adaptivePrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Constants.Spacing.medium)
    }
}

// MARK: - Current Prayer Card

struct CurrentPrayerCard: View {
    let prayerName: String
    let prayerTime: Date
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Current Prayer")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.adaptiveTextSecondary)
                .textCase(.uppercase)
            
            Text(prayerName)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.adaptiveText)
            
            Text(prayerTime.prayerTimeString)
                .font(.system(size: 20))
                .foregroundColor(.adaptiveTextSecondary)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Spacing.large)
        .background(
            ZStack {
                Color.adaptivePrimary.opacity(0.1)
                IslamicPatternView(opacity: 0.05, color: .adaptivePrimary)
                    .clipped()
            }
        )
        .cornerRadius(Constants.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(Color.adaptivePrimary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Next Prayer Card

struct NextPrayerCard: View {
    let prayerName: String
    let prayerTime: Date
    let currentTime: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Next Prayer")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.adaptiveTextSecondary)
                .textCase(.uppercase)
            
            Text(prayerName)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.adaptivePrimary)
            
            Text(prayerTime.prayerTimeString)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.adaptiveText)
            
            // Countdown
            Text(prayerTime.timeUntilString())
                .font(.system(size: 18))
                .foregroundColor(.adaptiveTextSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.adaptivePrimary.opacity(0.15))
                .cornerRadius(Constants.CornerRadius.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Spacing.extraLarge)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.adaptivePrimary.opacity(0.2),
                    Color.adaptivePrimary.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(Constants.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(Color.adaptivePrimary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - All Prayers Completed Card

struct AllPrayersCompletedCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 60))
                .foregroundColor(.adaptivePrimary)
            
            Text("All Prayers Completed")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.adaptiveText)
            
            Text("Excellent work today")
                .font(.system(size: 16))
                .foregroundColor(.adaptiveTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Spacing.extraLarge)
        .background(Color.adaptivePrimary.opacity(0.1))
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - Quick Actions Row

struct QuickActionsRow: View {
    @Binding var showWeek: Bool
    @Binding var showMonth: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                showWeek = true
            }) {
                Label("Week", systemImage: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.adaptivePrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptivePrimary.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
            }
            
            Button(action: {
                showMonth = true
            }) {
                Label("Month", systemImage: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.adaptivePrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptivePrimary.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
            }
        }
    }
}

// MARK: - Today's Prayers List

struct TodayPrayersList: View {
    let prayerTimes: PrayerTime
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Prayer Times")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.adaptiveText)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(prayerTimes.allPrayers.enumerated()), id: \.offset) { index, prayer in
                    PrayerTimeRow(
                        prayerName: prayer.name,
                        prayerTime: prayer.time,
                        isPassed: prayer.time.hasPassed
                    )
                    
                    if index < prayerTimes.allPrayers.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.adaptivePrimary.opacity(0.05))
            .cornerRadius(Constants.CornerRadius.medium)
        }
    }
}

// MARK: - Prayer Time Row

struct PrayerTimeRow: View {
    let prayerName: String
    let prayerTime: Date
    let isPassed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isPassed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isPassed ? .green : .adaptiveTextSecondary)
                .frame(width: 40)
            
            Text(prayerName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.adaptiveText)
            
            Spacer()
            
            Text(prayerTime.prayerTimeString)
                .font(.system(size: 16))
                .foregroundColor(.adaptiveTextSecondary)
        }
        .padding()
        .opacity(isPassed ? 0.6 : 1.0)
    }
}

// MARK: - Reusable Islamic Design Components

struct IslamicPatternView: View {
    var opacity: Double = 0.05
    var color: Color = .adaptivePrimary
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size = 60.0
                let rows = Int(geometry.size.height / size) + 1
                let cols = Int(geometry.size.width / size) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = Double(col) * size
                        let y = Double(row) * size
                        drawStar(in: &path, x: x + size/2, y: y + size/2, size: size/2)
                    }
                }
            }
            .stroke(color, lineWidth: 0.5)
            .opacity(opacity)
        }
    }
    
    private func drawStar(in path: inout Path, x: Double, y: Double, size: Double) {
        let stars = 8
        let angle = Double.pi * 2 / Double(stars)
        let innerRadius = size * 0.4
        
        for i in 0..<stars {
            let startAngle = angle * Double(i)
            let midAngle = startAngle + angle / 2
            
            let p1 = CGPoint(x: x + cos(startAngle) * size, y: y + sin(startAngle) * size)
            let p2 = CGPoint(x: x + cos(midAngle) * innerRadius, y: y + sin(midAngle) * innerRadius)
            
            if i == 0 {
                path.move(to: p1)
            } else {
                path.addLine(to: p1)
            }
            path.addLine(to: p2)
        }
        path.closeSubpath()
    }
}
