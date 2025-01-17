import SwiftUI

struct FoodRecognitionResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var recognizedFoods: [FoodRecognitionManager.RecognizedFood]
    let onSave: ([FoodRecognitionManager.RecognizedFood]) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach($recognizedFoods) { $food in
                    FoodItemView(food: $food)
                }
                
                Section {
                    HStack {
                        Text("总卡路里")
                        Spacer()
                        Text("\(Int(totalCalories))卡路里")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("识别结果")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    onSave(recognizedFoods.filter { $0.isSelected })
                    dismiss()
                }
            )
        }
    }
    
    private var totalCalories: Double {
        recognizedFoods
            .filter { $0.isSelected }
            .reduce(0) { $0 + $1.calories }
    }
}

struct FoodItemView: View {
    @Binding var food: FoodRecognitionManager.RecognizedFood
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle(isOn: $food.isSelected) {
                    Text(food.name)
                        .font(.headline)
                }
                Spacer()
                Text("\(Int(food.calories))卡路里")
                    .foregroundColor(.secondary)
            }
            
            if food.isSelected {
                Grid(alignment: .leading) {
                    GridRow {
                        if let protein = food.protein {
                            Text("蛋白质: \(String(format: "%.1f", protein))g")
                        }
                        if let carbs = food.carbs {
                            Text("碳水: \(String(format: "%.1f", carbs))g")
                        }
                        if let fat = food.fat {
                            Text("脂肪: \(String(format: "%.1f", fat))g")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
} 