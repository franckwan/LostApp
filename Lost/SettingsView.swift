import SwiftUI

struct SettingsView: View {
    @AppStorage("dailyCalorieTarget") private var dailyCalorieTarget = 2000.0
    
    var body: some View {
        Form {
            Section(header: Text("目标设置")) {
                HStack {
                    Text("每日卡路里目标")
                    Spacer()
                    TextField("卡路里", value: $dailyCalorieTarget, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section {
                Link(destination: URL(string: "https://www.example.com/privacy")!) {
                    Label("隐私政策", systemImage: "hand.raised.fill")
                }
                
                Link(destination: URL(string: "https://www.example.com/terms")!) {
                    Label("使用条款", systemImage: "doc.text.fill")
                }
            }
            
            Section {
                Text("版本 1.0.0")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("设置")
    }
} 