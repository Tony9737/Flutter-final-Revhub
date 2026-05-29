import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/audio/audio_manager.dart'; 
import 'features/auth/presentation/login_screen.dart';
import 'features/vehicle/presentation/pages/show_room_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase
  await Supabase.initialize(
    url: 'https://fsqrgqpthqtvxfpxxxod.supabase.co', // 替換成你的 Supabase 專案網址
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzcXJncXB0aHF0dnhmcHh4eG9kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4NzQyODUsImV4cCI6MjA5NDQ1MDI4NX0.IafRowtq29Z8ZjMFc6YN31qlPsi7r7AqljPwPr3yAt4', // 替換成你的 Anon Key
  );

  await AudioManager.instance.startBgm();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 檢查 Supabase 目前是否有快取的登入 Session
    final session = Supabase.instance.client.auth.currentSession;
    
    // 如果 session 存在，表示已登入，首頁直接給展示廳；否則給登入頁面
    final Widget initialScreen = session != null 
        ? const ShowRoomPage() 
        : const LoginScreen();

    return MaterialApp(
      title: "Tony's Showroom",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'AppFont', 
      ),
      // 將動態判斷好的畫面指定給 home
      home: initialScreen,
    );
  }
}

