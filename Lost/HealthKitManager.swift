import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // 定义所有支持的营养类型
    private let supportedTypes: [(HKQuantityTypeIdentifier, HKUnit)] = [
        (.dietaryEnergyConsumed, .kilocalorie()),
        (.dietaryProtein, .gram()),
        (.dietaryCarbohydrates, .gram()),
        (.dietaryFatTotal, .gram()),
        (.dietarySugar, .gram()),
        (.dietaryCaffeine, .gramUnit(with: .milli)),
        (.dietaryVitaminC, .gramUnit(with: .milli)),
        (.dietaryCalcium, .gramUnit(with: .milli)),
        (.dietaryIron, .gramUnit(with: .milli)),
        (.dietaryFiber, .gram()),
        (.dietarySodium, .gramUnit(with: .milli))
    ]
    
    private init() {}
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let types = supportedTypes.compactMap { identifier, _ in
            HKQuantityType.quantityType(forIdentifier: identifier)
        }
        
        let typesToShare = Set(types)
        let typesToRead = Set(types)
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            } catch {
                print("HealthKit authorization failed")
            }
        }
    }
    
    func syncMealToHealth(meal: Meal) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        var samples: [HKQuantitySample] = []
        
        // 卡路里
        if let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: meal.calories)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: meal.date, end: meal.date))
        }
        
        // 蛋白质
        if let protein = meal.protein,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: protein)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: meal.date, end: meal.date))
        }
        
        // 碳水化合物
        if let carbs = meal.carbohydrates,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let quantity = HKQuantity(unit: .gram(), doubleValue: carbs)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: meal.date, end: meal.date))
        }
        
        // 其他营养成分...（类似处理）
        if let caffeine = meal.caffeine,
           let type = HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine) {
            let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: caffeine)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: meal.date, end: meal.date))
        }
        
        // 批量保存所有样本
        healthStore.save(samples) { success, error in
            if let error = error {
                print("Error saving to HealthKit: \(error.localizedDescription)")
            }
        }
    }
    
    // 添加删除数据的方法
    func deleteMealFromHealth(date: Date) {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        // 获取所有支持的类型
        let types = supportedTypes.compactMap { identifier, _ in
            HKQuantityType.quantityType(forIdentifier: identifier)
        }
        
        // 设置查询的时间范围（使用精确的时间点）
        let startDate = date
        let endDate = date.addingTimeInterval(1) // 添加1秒，确保只删除这一条记录
        
        // 为每个类型删除数据
        for type in types {
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            
            healthStore.deleteObjects(
                of: type,
                predicate: predicate
            ) { success, count, error in
                if let error = error {
                    print("Error deleting from HealthKit: \(error.localizedDescription)")
                }
            }
        }
    }
} 