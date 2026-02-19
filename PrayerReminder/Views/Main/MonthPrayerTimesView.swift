import SwiftUI

struct MonthPrayerTimesView: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var selectedDayPrayers: PrayerTime? {
        viewModel.monthPrayerTimes.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                IslamicPatternView(opacity: 0.02)
                    .ignoresSafeArea()
                
                if viewModel.monthPrayerTimes.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading lunar calendar...")
                            .padding(.top)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Calendar Grid
                            calendarGrid
                                .padding()
                                .background(Color.adaptiveBackground)
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                                .padding(.horizontal)
                            
                            // Selected Day Details
                            if let prayers = selectedDayPrayers {
                                DetailedDayView(prayerTime: prayers)
                                    .padding(.horizontal)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.largeTitle)
                                        .foregroundColor(.adaptiveTextSecondary)
                                    Text("Select a date to see times")
                                        .foregroundColor(.adaptiveTextSecondary)
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Monthly Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.adaptiveTextSecondary)
                    }
                }
            }
            .task {
                if viewModel.monthPrayerTimes.isEmpty {
                    await viewModel.loadMonthPrayerTimes()
                }
            }
        }
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 16) {
            // Weekday Headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(1))
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.adaptiveTextSecondary)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.monthPrayerTimes) { prayerTime in
                    let isSelected = calendar.isDate(prayerTime.date, inSameDayAs: selectedDate)
                    let isToday = prayerTime.date.isToday
                    
                    VStack(spacing: 4) {
                        Text("\(calendar.component(.day, from: prayerTime.date))")
                            .font(.system(size: 15, weight: isSelected || isToday ? .bold : .medium))
                        
                        // Tiny dot if it's today
                        if isToday {
                            Circle()
                                .fill(isSelected ? .white : Color.adaptivePrimary)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(height: 45)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.adaptivePrimary : Color.clear)
                    )
                    .foregroundColor(isSelected ? .white : (isToday ? Color.adaptivePrimary : .adaptiveText))
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedDate = prayerTime.date
                        }
                    }
                }
            }
        }
    }
}
