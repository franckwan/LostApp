import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.date, order: .reverse) var meals: [Meal]
    @State private var selectedMeal: Meal?
    @State private var showingMealDetail = false
    
    init(sortOrder: SortOrder = .reverse) {
        _meals = Query(sort: \Meal.date, order: sortOrder)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(meals, id: \.id) { meal in
                    MealRowView(meal: meal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMeal = meal
                            showingMealDetail = true
                        }
                }
                .onDelete(perform: deleteMeals)
            }
            .navigationTitle("饮食记录")
            .sheet(item: $selectedMeal) { meal in
                NavigationView {
                    MealDetailView(meal: meal) {
                        selectedMeal = nil
                    }
                }
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
            }
        }
    }
    
    private func deleteMeals(_ indexSet: IndexSet) {
        for index in indexSet {
            let meal = meals[index]
            // 先从 HealthKit 删除数据
            HealthKitManager.shared.deleteMealFromHealth(date: meal.date)
            // 然后删除本地数据
            modelContext.delete(meal)
        }
    }
}

// 单行记录视图组件
struct MealRowView: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(meal.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(meal.calories))卡路里")
                    .foregroundColor(.secondary)
            }
            
            if let imageData = meal.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
            }
            
            if let notes = meal.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// 详情编辑视图
struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let meal: Meal
    let onDismiss: () -> Void
    
    @State private var editedName: String
    @State private var editedCalories: Double
    @State private var editedNotes: String
    @State private var editedProtein: Double
    @State private var editedCarbs: Double
    @State private var editedFat: Double
    @State private var editedCaffeine: Double
    @State private var showingDeleteConfirm = false
    
    init(meal: Meal, onDismiss: @escaping () -> Void) {
        self.meal = meal
        self.onDismiss = onDismiss
        
        // 初始化编辑状态
        _editedName = State(initialValue: meal.name)
        _editedCalories = State(initialValue: meal.calories)
        _editedNotes = State(initialValue: meal.notes ?? "")
        _editedProtein = State(initialValue: meal.protein ?? 0)
        _editedCarbs = State(initialValue: meal.carbohydrates ?? 0)
        _editedFat = State(initialValue: meal.fat ?? 0)
        _editedCaffeine = State(initialValue: meal.caffeine ?? 0)
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("餐食名称", text: $editedName)
                
                HStack {
                    Text("卡路里")
                    Spacer()
                    TextField("卡路里", value: $editedCalories, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                TextField("备注", text: $editedNotes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section(header: Text("营养成分")) {
                HStack {
                    Text("蛋白质 (g)")
                    Spacer()
                    TextField("0", value: $editedProtein, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("碳水化合物 (g)")
                    Spacer()
                    TextField("0", value: $editedCarbs, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("脂肪 (g)")
                    Spacer()
                    TextField("0", value: $editedFat, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("咖啡因 (mg)")
                    Spacer()
                    TextField("0", value: $editedCaffeine, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if let imageData = meal.imageData,
               let uiImage = UIImage(data: imageData) {
                Section(header: Text("照片")) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("删除记录")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("记录详情")
        .navigationBarItems(
            leading: Button("取消") {
                onDismiss()
            },
            trailing: Button("保存") {
                saveMeal()
                onDismiss()
            }
        )
        .alert("确认删除", isPresented: $showingDeleteConfirm) {
            Button("删除", role: .destructive) {
                deleteMeal()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除这条记录吗？此操作不可撤销。")
        }
    }
    
    private func saveMeal() {
        // 先删除旧的 HealthKit 数据
        HealthKitManager.shared.deleteMealFromHealth(date: meal.date)
        
        // 更新本地数据
        meal.name = editedName
        meal.calories = editedCalories
        meal.notes = editedNotes
        meal.protein = editedProtein > 0 ? editedProtein : nil
        meal.carbohydrates = editedCarbs > 0 ? editedCarbs : nil
        meal.fat = editedFat > 0 ? editedFat : nil
        meal.caffeine = editedCaffeine > 0 ? editedCaffeine : nil
        
        // 同步新数据到 HealthKit
        HealthKitManager.shared.syncMealToHealth(meal: meal)
        
        onDismiss()
    }
    
    private func deleteMeal() {
        // 先从 HealthKit 删除数据
        HealthKitManager.shared.deleteMealFromHealth(date: meal.date)
        
        // 然后删除本地数据
        modelContext.delete(meal)
        onDismiss()
    }
}

// 确保 Meal 符合 Identifiable 协议
extension Meal: Identifiable { } 