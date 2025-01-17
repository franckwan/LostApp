import SwiftUI
import SwiftData
import PhotosUI

struct MealLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var mealName = ""
    @State private var calories: Double = 0
    @State private var notes = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingSaveSuccess = false
    @State private var showingNutritionDetails = false
    @State private var protein: Double = 0
    @State private var carbohydrates: Double = 0
    @State private var fat: Double = 0
    @State private var caffeine: Double = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("餐食信息")) {
                    TextField("餐食名称", text: $mealName)
                    
                    HStack {
                        Text("卡路里")
                        Spacer()
                        TextField("卡路里", value: $calories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("照片")) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let selectedImageData,
                           let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                        } else {
                            Label("添加照片", systemImage: "camera")
                        }
                    }
                }
                
                Section(header: Text("营养成分")) {
                    Button("添加详细营养信息") {
                        showingNutritionDetails = true
                    }
                }
                
                Button(action: saveMeal) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
            .navigationTitle("记录餐食")
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
            .alert("保存成功", isPresented: $showingSaveSuccess) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("已成功记录餐食信息")
            }
            .sheet(isPresented: $showingNutritionDetails) {
                NavigationView {
                    Form {
                        Section(header: Text("主要营养素")) {
                            HStack {
                                Text("蛋白质 (g)")
                                Spacer()
                                TextField("0", value: $protein, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("碳水化合物 (g)")
                                Spacer()
                                TextField("0", value: $carbohydrates, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("脂肪 (g)")
                                Spacer()
                                TextField("0", value: $fat, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        Section(header: Text("其他营养素")) {
                            HStack {
                                Text("咖啡因 (mg)")
                                Spacer()
                                TextField("0", value: $caffeine, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            // 可以添加更多营养素...
                        }
                    }
                    .navigationTitle("营养详情")
                    .navigationBarItems(trailing: Button("完成") {
                        showingNutritionDetails = false
                    })
                }
            }
        }
    }
    
    private func saveMeal() {
        let meal = Meal(name: mealName,
                       calories: calories,
                       imageData: selectedImageData,
                       notes: notes,
                       protein: protein > 0 ? protein : nil,
                       carbohydrates: carbohydrates > 0 ? carbohydrates : nil,
                       fat: fat > 0 ? fat : nil,
                       caffeine: caffeine > 0 ? caffeine : nil)
        
        modelContext.insert(meal)
        
        // 同步到 HealthKit
        HealthKitManager.shared.syncMealToHealth(meal: meal)
        
        // 重置表单
        resetForm()
        showingSaveSuccess = true
    }
    
    private func resetForm() {
        mealName = ""
        calories = 0
        notes = ""
        selectedImageData = nil
        selectedItem = nil
        protein = 0
        carbohydrates = 0
        fat = 0
        caffeine = 0
    }
} 