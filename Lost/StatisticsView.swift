import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.date) var meals: [Meal]
    
    init() {
        _meals = Query(sort: \Meal.date)
    }
    
    var dailyCalories: [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }
        
        return grouped
            .map { (date, meals) in
                let totalCalories = meals.reduce(0.0) { sum, meal in
                    sum + (meal.calories.isNaN ? 0 : meal.calories)
                }
                return (date, totalCalories)
            }
            .sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        List {
            if !dailyCalories.isEmpty {
                Section {
                    Chart(dailyCalories, id: \.0) { day in
                        BarMark(
                            x: .value("日期", day.0, unit: .day),
                            y: .value("卡路里", max(0, day.1))
                        )
                        .foregroundStyle(Color.blue.gradient)
                    }
                    .frame(height: 200)
                } header: {
                    Text("每日卡路里摄入")
                }
            } else {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            
            Section {
                HStack {
                    Text("平均每日摄入")
                    Spacer()
                    Text("\(Int(max(0, averageCalories)))卡路里")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("统计")
    }
    
    private var averageCalories: Double {
        guard !dailyCalories.isEmpty else { return 0 }
        let total = dailyCalories.reduce(0.0) { $0 + $1.1 }
        return total / Double(dailyCalories.count)
    }
} 