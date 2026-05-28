import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Supabase
  await Supabase.initialize(
    url: 'https://fsqrgqpthqtvxfpxxxod.supabase.co', // 替換成你的 Supabase 專案網址
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzcXJncXB0aHF0dnhmcHh4eG9kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4NzQyODUsImV4cCI6MjA5NDQ1MDI4NX0.IafRowtq29Z8ZjMFc6YN31qlPsi7r7AqljPwPr3yAt4', // 替換成你的 Anon Key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


