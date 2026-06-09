import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  // 取得 Supabase 的客戶端實例
  SupabaseClient get client => Supabase.instance.client;

  // 如果未來要改用 http 或 dio，也可以在這裡統一初始化
}