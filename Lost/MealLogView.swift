import PhotosUI
import SwiftData
import SwiftUI

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
  @State private var recognizedFoods: [FoodRecognitionManager.RecognizedFood] = []
  @State private var showingRecognitionResult = false
  @State private var isProcessingImage = false
  @State private var showingAlert = false

  var body: some View {
    NavigationView {
      ZStack {
        Form {
          Section(header: Text("餐食信息")) {
            TextField("餐食名称", text: $mealName)
              .onTapGesture {
                hideKeyboard()
              }

            HStack {
              Text("卡路里")
              Spacer()
              TextField("卡路里", value: $calories, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }

            TextField("备注", text: $notes, axis: .vertical)
              .lineLimit(3...6)
              .onTapGesture {
                hideKeyboard()
              }
          }

          Section(header: Text("AI识别餐食信息")) {
            TextField("AI识别餐食信息", text: $notes, axis: .vertical)
              .lineLimit(3...6)
              .onTapGesture {
                hideKeyboard()
              }
          }

          Section(header: Text("照片")) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
              if let selectedImageData,
                let uiImage = UIImage(data: selectedImageData)
              {
                Image(uiImage: uiImage)
                  .resizable()
                  .scaledToFit()
                  .frame(maxHeight: 200)
                  .contentShape(Rectangle())
              } else {
                Label("添加照片", systemImage: "camera")
                  .frame(maxWidth: .infinity, minHeight: 44)
              }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .padding(.vertical, 8)
          }

          Section(header: Text("营养成分")) {
            Button("添加详细营养信息") {
              showingNutritionDetails = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
          }

          Button(action: saveMeal) {
            Text("保存")
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
              .padding(.vertical, 12)
          }
          .buttonStyle(.plain)
          .listRowBackground(Color.blue)
          .contentShape(Rectangle())
          .listRowInsets(EdgeInsets())
          .padding(.vertical, 4)
        }
        
        if isProcessingImage {
          Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
          ProgressView("正在识别食物...")
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .foregroundColor(.white)
        }
      }
      .navigationTitle("记录餐食")
      .onChange(of: selectedItem) { oldValue, newValue in
        Task {
          if let data = try? await newValue?.loadTransferable(type: Data.self) {
            selectedImageData = data
            // 开始识别
            await recognizeFood(from: data)
          }
        }
      }
      .alert("保存成功", isPresented: $showingSaveSuccess) {
        Button("确定", role: .cancel) {}
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
                  .onTapGesture {
                    hideKeyboard()
                  }
              }

              HStack {
                Text("碳水化合物 (g)")
                Spacer()
                TextField("0", value: $carbohydrates, format: .number)
                  .keyboardType(.decimalPad)
                  .multilineTextAlignment(.trailing)
                  .onTapGesture {
                    hideKeyboard()
                  }
              }

              HStack {
                Text("脂肪 (g)")
                Spacer()
                TextField("0", value: $fat, format: .number)
                  .keyboardType(.decimalPad)
                  .multilineTextAlignment(.trailing)
                  .onTapGesture {
                    hideKeyboard()
                  }
              }
            }

            Section(header: Text("其他营养素")) {
              HStack {
                Text("咖啡因 (mg)")
                Spacer()
                TextField("0", value: $caffeine, format: .number)
                  .keyboardType(.decimalPad)
                  .multilineTextAlignment(.trailing)
                  .onTapGesture {
                    hideKeyboard()
                  }
              }
            }
          }
          .navigationTitle("营养详情")
          .navigationBarItems(
            trailing: Button("完成") {
              showingNutritionDetails = false
            })
        }
      }
      .sheet(isPresented: $showingRecognitionResult) {
        FoodRecognitionResultView(
          recognizedFoods: $recognizedFoods,
          onSave: { foods in
            // 将识别结果合并到当前记录
            let totalCalories = foods.reduce(0) { $0 + $1.calories }
            calories = totalCalories

            // 合并营养成分
            protein = foods.reduce(0) { $0 + ($1.protein ?? 0) }
            carbohydrates = foods.reduce(0) { $0 + ($1.carbs ?? 0) }
            fat = foods.reduce(0) { $0 + ($1.fat ?? 0) }

            // 更新名称
            if !foods.isEmpty {
              mealName = foods.map { $0.name }.joined(separator: "、")
            }
          }
        )
      }
      .alert("未识别到食物", isPresented: $showingAlert) {
        Button("确定", role: .cancel) {}
      } message: {
        Text("抱歉，未能在图片中识别到任何食物。请尝试使用其他图片或手动输入信息。")
      }
    }
    .onTapGesture {
      hideKeyboard()  // 确保点击空白地方也能隐藏键盘
    }
  }

  private func saveMeal() {
    let meal = Meal(
      name: mealName,
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

  private func recognizeFood(from imageData: Data) async {
    isProcessingImage = true
    defer { isProcessingImage = false }

    do {
      recognizedFoods = try await FoodRecognitionManager.shared.recognizeFoodInImage(imageData)
      if !recognizedFoods.isEmpty {
        showingRecognitionResult = true
      } else {
        // 当未识别到食物时显示提示框
        showingAlert = true
      }
    } catch {
      print("Food recognition failed: \(error)")
    }
  }

  // 隐藏键盘的方法
  private func hideKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
