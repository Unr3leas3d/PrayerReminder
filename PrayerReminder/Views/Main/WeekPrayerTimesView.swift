import SwiftUI

struct WeekPrayerTimesView: View {
    @ObservedObject var viewModel: PrayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    // Smooth transition between days
    var selectedPrayerTime: PrayerTime? {
        viewModel.weekPrayerTimes.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                IslamicPatternView(opacity: 0.03)
                    .ignoresSafeArea()
                
                if viewModel.weekPrayerTimes.isEmpty {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Calculating times...")
                            .padding(.top)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Horizontal Day Selector
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.weekPrayerTimes) { prayerTime in
                                        DaySelectorItem(
                                            date: prayerTime.date,
                                            isSelected: Calendar.current.isDate(prayerTime.date, inSameDayAs: selectedDate)
                                        )
                                        .id(prayerTime.date)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedDate = prayerTime.date
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                            .onAppear {
                                proxy.scrollTo(selectedDate, anchor: .center)
                            }
                        }
                        
                        Divider()
                            .opacity(0.1)
                        
                        // Detailed Day View
                        ScrollView {
                            if let prayerTime = selectedPrayerTime {
                                DetailedDayView(prayerTime: prayerTime)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    .padding()
                            } else {
                                ContentUnavailableView("No Data", systemImage: "calendar.badge.exclamationmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Islamic Calendar")
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
                if viewModel.weekPrayerTimes.isEmpty {
                    await viewModel.loadWeekPrayerTimes()
                }
                // Default to today if items loaded
                if let today = viewModel.weekPrayerTimes.first(where: { $0.date.isToday }) {
                    selectedDate = today.date
                }
            }
        }
    }
}

// MARK: - Components

struct DaySelectorItem: View {
    let date: Date
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : .adaptiveTextSecondary)
            
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isSelected ? .white : .adaptiveText)
        }
        .frame(width: 60, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.adaptivePrimary : Color.adaptivePrimary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.adaptivePrimary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: isSelected ? Color.adaptivePrimary.opacity(0.3) : Color.clear, radius: 8, y: 4)
    }
}

struct DetailedDayView: View {
    let prayerTime: PrayerTime
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Card
            VStack(spacing: 8) {
                Text(prayerTime.hijriDate)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.adaptivePrimary)
                
                Text(prayerTime.date.fullDateString)
                    .font(.subheadline)
                    .foregroundColor(.adaptiveTextSecondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.adaptivePrimary.opacity(0.05))
            .cornerRadius(20)
            
            // Prayers List
            VStack(spacing: 12) {
                ForEach(prayerTime.allPrayers, id: \.name) { prayer in
                    PrayerDetailRow(
                        name: prayer.name,
                        time: prayer.time,
                        isToday: prayerTime.date.isToday
                    )
                }
            }
        }
    }
}

struct PrayerDetailRow: View {
    let name: String
    let time: Date
    let isToday: Bool
    
    var isPast: Bool {
        isToday && time < Date()
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconForPrayer(name))
                .font(.system(size: 18))
                .foregroundColor(isPast ? .adaptiveTextSecondary : .adaptivePrimary)
                .frame(width: 32)
            
            Text(name)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(isPast ? .adaptiveTextSecondary : .adaptiveText)
            
            Spacer()
            
            Text(time.prayerTimeString)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(isPast ? .adaptiveTextSecondary : .adaptivePrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPast ? Color.clear : Color.adaptivePrimary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func iconForPrayer(_ name: String) -> String {
        switch name {
        case "Fajr": return "sun.horizon.fill"
        case "Dhuhr": return "sun.max.fill"
        case "Asr": return "sun.min.fill"
        case "Maghrib": return "moon.stars.fill"
        case "Isha": return "moon.fill"
        default: return "clock.fill"
        }
    }
}
