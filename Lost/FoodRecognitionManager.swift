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

  // 图片识别
  func recognizeFoodInImage(_ imageData: Data) async throws -> [RecognizedFood] {
    print("开始识别图片...")

    // 检查和处理图片
    guard let image = UIImage(data: imageData) else {
      throw NSError(
        domain: "FoodRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的图片数据"])
    }

    // 压缩图片以确保不超过 API 限制
    let maxSize: CGFloat = 1024
    let scaledImage: UIImage
    if image.size.width > maxSize || image.size.height > maxSize {
      let scale = maxSize / max(image.size.width, image.size.height)
      let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      image.draw(in: CGRect(origin: .zero, size: newSize))
      scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
      UIGraphicsEndImageContext()
    } else {
      scaledImage = image
    }

    // 转换为 JPEG 数据
    guard let jpegData = scaledImage.jpegData(compressionQuality: 0.8) else {
      throw NSError(
        domain: "FoodRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片转换失败"])
    }

    let base64Image = jpegData.base64EncodedString()
    print("图片处理完成，大小: \(jpegData.count) bytes")

    // 更新为新的 API 端点
    let url = URL(
      string:
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=\(geminiAPIKey)"
    )!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // 构建提示词
    let prompt = """
      请识别图片中的食物，并提供以下信息：
      1. 食物名称（中文）
      2. 每份的卡路里
      3. 蛋白质含量(g)
      4. 碳水化合物含量(g)
      5. 脂肪含量(g)

      请仔细观察图片中的每一个食物，即使不确定具体的营养成分，也请尽量给出估计值。
      如果看到多个食物，请分别列出。

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

      只返回JSON数据，不要其他解释。如果完全无法识别，请返回空数组 []。
      """

    // 构建请求体
    let requestBody: [String: Any] = [
      "contents": [
        [
          "parts": [
            [
              "text": prompt
            ],
            [
              "inline_data": [
                "mime_type": "image/jpeg",
                "data": base64Image,
              ]
            ],
          ]
        ]
      ],
      "generationConfig": [
        "maxOutputTokens": 2048,
        "topP": 1,
        "temperature": 0.4,
        "topK": 32,
      ],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    // 打印请求信息
    print("发送请求...")

    // 发送请求
    let (data, response) = try await URLSession.shared.data(for: request)

    // 打印响应信息
    if let httpResponse = response as? HTTPURLResponse {
      print("响应状态码: \(httpResponse.statusCode)")
      if let responseString = String(data: data, encoding: .utf8) {
        print("API 响应: \(responseString)")
      }
    }

    // 解析响应
    let jsonResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
    let content = jsonResponse.candidates.first?.content.parts.first?.text ?? "[]"
    let cleanContent = content.replacingOccurrences(of: "```json", with: "")
      .replacingOccurrences(of: "```", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    print("\n=== AI 返回的结果 ===")
    print(cleanContent)
    print("==================\n")

    // 解析 JSON
    if let jsonData = cleanContent.data(using: .utf8),
      let foodArray = try? JSONDecoder().decode([FoodData].self, from: jsonData)
    {
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
    throw NSError(
      domain: "FoodRecognition", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析返回的数据"])
  }

  // 文本识别
  func recognizeFoodFromText(_ text: String) async throws -> [RecognizedFood] {
    print("开始分析文本...")
    return try await recognizeFood(withText: text)
  }

  private func recognizeFood(withImage base64Image: String? = nil, withText text: String? = nil)
    async throws -> [RecognizedFood]
  {
    // 准备请求
    let url = URL(
      string:
        "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro:generateContent?key=\(geminiAPIKey)"
    )!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // 构建提示词
    let prompt = """
      请分析以下食物信息，并提供详细的营养成分数据：
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

    // 构建请求体
    var parts: [[String: Any]] = [["text": prompt]]

    if let base64Image = base64Image {
      parts.append([
        "inline_data": [
          "mime_type": "image/jpeg",
          "data": base64Image,
        ]
      ])
    }

    if let text = text {
      parts.append(["text": "\n分析的食物描述：\(text)"])
    }

    let requestBody: [String: Any] = [
      "contents": [
        [
          "parts": parts
        ]
      ],
      "generationConfig": [
        "maxOutputTokens": 2048,
        "topP": 1,
        "temperature": 0.4,
        "topK": 32,
      ],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    // 打印请求信息
    print("发送请求...")
    if let requestString = String(data: request.httpBody!, encoding: .utf8) {
      print("请求体: \(requestString)")
    }

    // 发送请求
    let (data, response) = try await URLSession.shared.data(for: request)

    // 打印响应状态
    if let httpResponse = response as? HTTPURLResponse {
      print("响应状态码: \(httpResponse.statusCode)")
    }

    // 错误处理
    if let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode != 200
    {
      if let errorString = String(data: data, encoding: .utf8) {
        print("错误响应: \(errorString)")
        throw NSError(
          domain: "FoodRecognition", code: httpResponse.statusCode,
          userInfo: [NSLocalizedDescriptionKey: "识别服务出错，请稍后重试"])
      }
      throw NSError(
        domain: "FoodRecognition", code: -1,
        userInfo: [NSLocalizedDescriptionKey: "未知错误"])
    }

    // 解析响应
    let jsonResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
    let content = jsonResponse.candidates.first?.content.parts.first?.text ?? "[]"
    let cleanContent = content.replacingOccurrences(of: "```json", with: "")
      .replacingOccurrences(of: "```", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    print("\n=== AI 返回的结果 ===")
    print(cleanContent)
    print("==================\n")

    // 解析 JSON
    if let jsonData = cleanContent.data(using: .utf8),
      let foodArray = try? JSONDecoder().decode([FoodData].self, from: jsonData)
    {
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
    throw NSError(
      domain: "FoodRecognition", code: -1,
      userInfo: [NSLocalizedDescriptionKey: "无法解析返回的数据"])
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
