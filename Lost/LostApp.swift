//
//  LostApp.swift
//  Lost
//
//  Created by franck.wan on 2025/1/17.
//

import SwiftUI
import SwiftData
import HealthKit

@main
struct LostApp: App {
    // 将 HealthKit 管理移到单独的类中
    private let healthKitManager = HealthKitManager.shared
    
    init() {
        // 在初始化时请求 HealthKit 权限
        healthKitManager.requestAuthorization()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Meal.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TabView {
                MealLogView()
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                        Text("记录")
                    }
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("历史")
                    }
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("我的")
                    }
            }
            .modelContainer(sharedModelContainer)
        }
    }
}
