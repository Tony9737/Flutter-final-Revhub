import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/config/local_secrets.dart';

class GeminiRecommendationService {
  // 傳入你在 Google AI Studio 申請到的 API Key
  GeminiRecommendationService({required String apiKey});

  /// 發送使用者需求與車輛清單給 Gemini，並回傳推薦的 carID 列表與推薦原因文字
  Future<Map<String, dynamic>> fetchAiRecommendations({
    required String userInput,
    required String vehiclesJsonContext,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // 使用速度快、高性價比且支援結構化輸出的模型
      apiKey: geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        // 規定 AI 必須嚴格遵守此 JSON 結構回傳
        responseSchema: Schema.object(
          properties: {
            'success': Schema.boolean(description: '是否成功找到符合條件的車輛'),
            'ai_reason': Schema.string(description: 'AI 對於這次推薦的整體總結分析與導購建議描述'),
            'recommended_ids': Schema.array(
              items: Schema.string(description: '符合推薦條件的車輛 carID'),
              description: '所有符合條件的車款 ID 陣列，如果有很多符合，請盡可能列出整個類別',
            ),
          },
        ),
      ),
    );

    final prompt = '''
你是一位專業的高級汽車顧問。請根據下方提供的【資料庫現有車輛清單】，針對【使用者的尋車需求】進行深度分析與精準篩選。

限制條件：
1. 請不要推薦任何「不在」下方清單中的車款。
2. 如果使用者指定某個類別、預算或國家，請把資料庫中所有符合該類別或特徵的車輛 ID 統統找出來放入推薦列表。
3. 你的分析與建議語氣必須專業、奢華且具說服力。

【資料庫現有車輛清單】:
$vehiclesJsonContext

【使用者的尋車需求】:
"$userInput"
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        return {'success': false, 'ai_reason': 'AI 暫時無法回應，請稍後再試。', 'recommended_ids': <String>[]};
      }

      // 解析結構化 JSON
      final Map<String, dynamic> jsonResult = jsonDecode(responseText);
      return jsonResult;
    } catch (e) {
      // print('Gemini 推薦出錯: $e');
      return {
        'success': false,
        'ai_reason': '連線至 AI 車輛導購專家時發生錯誤：$e',
        'recommended_ids': <String>[]
      };
    }
  }
}