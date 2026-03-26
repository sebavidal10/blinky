import SwiftUI

struct CalendarDotsView: View {
    @Binding var selectedDate: Date
    @EnvironmentObject var timer: SessionManager
    
    @State private var monthOffset: Int = 0
    
    private let calendar = Calendar.current
    private let daysOfWeek = [
        Localization.at("Sun", "Dom"), 
        Localization.at("Mon", "Lun"), 
        Localization.at("Tue", "Mar"), 
        Localization.at("Wed", "Mie"), 
        Localization.at("Thu", "Jue"), 
        Localization.at("Fri", "Vie"), 
        Localization.at("Sat", "Sab")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Month Header
            HStack {
                Button(action: { monthOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Button(action: { monthOffset += 1 }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Days of Week
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid
            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, 
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                hasActivity: timer.hasActivity(on: date)) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: Localization.resolvedLanguage)
        let date = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        return formatter.string(from: date).capitalized
    }
    
    private func generateDays() -> [Date?] {
        let currentMonth = calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let startDay = calendar.component(.weekday, from: firstOfMonth) - 1 // 0 = Sunday
        
        var days: [Date?] = Array(repeating: nil, count: startDay)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasActivity: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
                
                Circle()
                    .fill(isSelected ? .white : .accentColor)
                    .frame(width: 3, height: 3)
                    .opacity(hasActivity ? 1 : 0)
            }
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
