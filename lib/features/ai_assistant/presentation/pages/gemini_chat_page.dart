import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/config/local_secrets.dart';

const Color _gold = Color(0xFFD4AF37);

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  late final ChatSession _chatSession;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  void _initGemini() {
    // 初始化模型（這裡選 gemini-2.5-flash）
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: geminiApiKey,
      // 注入專屬人設，讓 Gemini 變成 Revhub 的專業燃油車推廣大師
      systemInstruction: Content.system(
        '你是一位熱血且資深的燃油車專家，目前在名為「Revhub」的線上車輛展示平台服務。'
        '你的任務是熱情、專業且幽默地與用戶討論各種車款，著重介紹燃油車的規格、背景故事與最靈魂的「引擎聲浪」。'
        '請用繁體中文（台灣）回答。回答時多帶一點熱血、玩車社群的口吻。'
        '如果用戶提到電動車，請用幽默、不失禮貌的方式提醒他：「燃油車的靈魂來自聲浪，沒有了聲浪，不如去開電車就好！」'
      ),
    );

    // 開啟帶有歷史紀錄的對話 Session
    _chatSession = model.startChat();

    // 加入初始迎賓訊息
    _messages.add({
      'isUser': false,
      'text': '嘿！熱血的車友！歡迎來到 Revhub AI 聊車室。👋\n想聊聊哪台經典性能車？或是需要我為你推薦什麼燃油猛獸嗎？引擎聲浪才是男人的浪漫！',
    });
  }

  Future<void> _sendMessage() async {
    final userText = _textController.text.trim();
    if (userText.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add({'isUser': true, 'text': userText});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // 將訊息發送給 Gemini 並等待回覆
      final response = await _chatSession.sendMessage(Content.text(userText));
      
      setState(() {
        _messages.add({
          'isUser': false,
          'text': response.text ?? '（引擎熄火了...請再試一次）',
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'isUser': false,
          'text': '糟糕，網路回火爆震了！錯誤訊息：$e',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. 頂部 Bar 標題
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0x33000000),
            border: Border(bottom: BorderSide(color: Color(0x11D4AF37))),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: _gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Gemini AI 車輛推薦專家',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        // 2. 聊天對話清單
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                // 顯示 AI 正在思考的讀取動畫
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1B18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: _gold, strokeWidth: 2),
                    ),
                  ),
                );
              }

              final msg = _messages[index];
              final isUser = msg['isUser'] as bool;

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? _gold : const Color(0xFF1F1B18),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    border: isUser 
                        ? null 
                        : Border.all(color: const Color(0x33D4AF37), width: 0.8),
                  ),
                  child: Text(
                    msg['text'] as String,
                    style: TextStyle(
                      color: isUser ? Colors.black : const Color(0xFFF3EAD5),
                      fontSize: 15,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 3. 底部文字輸入框
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF100D0A),
            border: Border(top: BorderSide(color: Color(0x11D4AF37))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Color(0xFFF3EAD5)),
                  decoration: InputDecoration(
                    hintText: '跟 AI 聊聊熱血的燃油車...',
                    hintStyle: const TextStyle(color: Color(0xFF6E6450), fontSize: 14),
                    fillColor: const Color(0xFF1A1613),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0x66D4AF37), width: 1),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: _gold,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}