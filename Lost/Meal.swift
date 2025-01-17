import Foundation
import SwiftData
import HealthKit

@Model
final class Meal {
    var id: UUID
    var name: String
    var calories: Double
    var date: Date
    var imageData: Data?
    var notes: String?
    
    // 添加更多营养成分
    var protein: Double?         // 蛋白质 (g)
    var carbohydrates: Double?   // 碳水化合物 (g)
    var fat: Double?            // 脂肪 (g)
    var sugar: Double?          // 糖 (g)
    var caffeine: Double?       // 咖啡因 (mg)
    var vitaminC: Double?       // 维生素C (mg)
    var calcium: Double?        // 钙 (mg)
    var iron: Double?           // 铁 (mg)
    var fiber: Double?          // 膳食纤维 (g)
    var sodium: Double?         // 钠 (mg)
    
    init(name: String, 
         calories: Double, 
         imageData: Data? = nil, 
         notes: String? = nil,
         protein: Double? = nil,
         carbohydrates: Double? = nil,
         fat: Double? = nil,
         sugar: Double? = nil,
         caffeine: Double? = nil,
         vitaminC: Double? = nil,
         calcium: Double? = nil,
         iron: Double? = nil,
         fiber: Double? = nil,
         sodium: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.date = Date()
        self.imageData = imageData
        self.notes = notes
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.sugar = sugar
        self.caffeine = caffeine
        self.vitaminC = vitaminC
        self.calcium = calcium
        self.iron = iron
        self.fiber = fiber
        self.sodium = sodium
    }
} 