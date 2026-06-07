// features/vehicle/data/datasource/vehicle_remote_datasource.dart

import '../../../../core/network/api_client.dart';

/// 遠端車輛資料源：負責直接發送 RESTful API 請求至 Supabase 雲端
class VehicleRemoteDataSource {
  final ApiClient apiClient;

  VehicleRemoteDataSource({required this.apiClient});

  /// API 請求：透過 SQL Join 語法一次將『貼文(posts)』與其對應的『車輛基本規格(vehicles)』完整拉回來
  /// 這在標準 REST 概念中相當於：GET /posts?select=*,vehicles(*)
  Future<List<Map<String, dynamic>>> fetchVehiclePostsWithSpecs() async {
    try {
      // 透過封裝好的 apiClient 取得 Supabase 實例
      // 使用你的新欄位設計，發出關聯查詢的 GET 請求
      final List<dynamic> response = await apiClient.client
          .from('posts')
          .select('*, vehicles(*)')
          // 可以加上排序，讓最新同步的貼文排在最前面
          .order('created_at', ascending: false);

      // 將回傳的動態 List 轉為 Flutter 規範的 Map 列表
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // 拋出明確的異常資訊，方便未來在 Controller 或頁面上捕捉並彈出錯誤視窗
      throw Exception('❌ [API 錯誤] 遠端撈取車輛與貼文聯體資料失敗: $e');
    }
  }
}