import SwiftUI
import HealthKit

struct ProfileView: View {
    @State private var isHealthKitAuthorized = false
    private let healthStore = HKHealthStore()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                        Toggle("同步到健康", isOn: $isHealthKitAuthorized)
                            .onChange(of: isHealthKitAuthorized) { oldValue, newValue in
                                if newValue {
                                    requestHealthKitPermission()
                                }
                            }
                    }
                } header: {
                    Text("健康数据")
                }
                
                Section {
                    NavigationLink {
                        StatisticsView()
                    } label: {
                        Label("统计分析", systemImage: "chart.bar.fill")
                    }
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("设置", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("我的")
        }
        .onAppear {
            checkHealthKitAuthorization()
        }
    }
    
    private func checkHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead = Set([
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ])
        
        healthStore.getRequestStatusForAuthorization(toShare: typesToRead, read: typesToRead) { status, error in
            DispatchQueue.main.async {
                isHealthKitAuthorized = status == .unnecessary
            }
        }
    }
    
    private func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToShare = Set([
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ])
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToShare) { success, error in
            DispatchQueue.main.async {
                isHealthKitAuthorized = success
            }
        }
    }
} 