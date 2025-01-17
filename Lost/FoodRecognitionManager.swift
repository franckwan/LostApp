import Foundation
import UIKit

class FoodRecognitionManager {
    static let shared = FoodRecognitionManager()
    private let geminiAPIKey = Config.geminiAPIKey
    
    // 识别结果的数据结构
    struct RecognizedFood: Identifiable {
        let id = UUID()
        let name: String
        var calories: Double
        var protein: Double?
        var carbs: Double?
        var fat: Double?
        var isSelected: Bool = true
    }
    
    private init() {}
    
    func recognizeFoodInImage(_ imageData: Data) async throws -> [RecognizedFood] {
        print("开始识别图片...")
        
        // 将图片转换为 base64
        let base64Image = imageData.base64EncodedString()
        print("图片转换完成，大小: \(base64Image.count) 字符")
        
        // 准备请求
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=\(geminiAPIKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            请识别图片中的食物，并提供以下信息：
                            1. 食物名称（中文）
                            2. 每份的卡路里
                            3. 蛋白质含量(g)
                            4. 碳水化合物含量(g)
                            5. 脂肪含量(g)
                            
                            请以JSON格式返回，格式如下：
                            [
                              {
                                "name": "食物名称",
                                "calories": 100,
                                "protein": 10,
                                "carbs": 20,
                                "fat": 5
                              }
                            ]
                            
                            只返回JSON数据，不要其他解释。如果无法识别，请返回空数组 []。
                            """
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 打印请求体
        if let requestString = String(data: request.httpBody!, encoding: .utf8) {
            print("发送请求体: \(requestString)")
        }
        
        // 发送请求
        print("正在发送请求...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 打印响应状态
        if let httpResponse = response as? HTTPURLResponse {
            print("响应状态码: \(httpResponse.statusCode)")
        }
        
        // 打印原始响应
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("原始响应: \(rawResponse)")
        }
        
        // 错误信息打印
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200,
           let errorString = String(data: data, encoding: .utf8) {
            print("错误响应: \(errorString)")
        }
        
        // 解析响应
        let jsonResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let content = jsonResponse.candidates.first?.content.parts.first?.text ?? "[]"
        let cleanContent = content.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        print("\n=== AI 返回的结果 ===")
        print(cleanContent)
        print("==================\n")
        
        // 解析 JSON 响应为食物数组
        if let jsonData = cleanContent.data(using: .utf8),
           let foodArray = try? JSONDecoder().decode([FoodData].self, from: jsonData) {
            print("成功解析到 \(foodArray.count) 个食物项")
            return foodArray.map { food in
                print("- \(food.name): \(food.calories)卡路里")
                return RecognizedFood(
                    name: food.name,
                    calories: food.calories,
                    protein: food.protein,
                    carbs: food.carbs,
                    fat: food.fat
                )
            }
        }
        
        print("解析响应失败")
        throw NSError(domain: "FoodRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}

// Gemini API 响应模型
struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
}

// 食物数据模型
struct FoodData: Codable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
} 
