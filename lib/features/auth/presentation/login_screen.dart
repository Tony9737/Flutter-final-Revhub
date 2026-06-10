import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../vehicle/presentation/pages/show_room_page.dart';

// 定義登入類型的狀態列舉
enum LoginType { none, email, google, facebook, github }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isObscure = true;
  bool _isSignUpMode = false;

  // 追蹤載入狀態
  LoginType _currentLoadingType = LoginType.none;

  // 配色常數
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldLight = Color(0xFFE5C158);
  static const Color _goldDark = Color(0xFFB8942A);
  static const Color _textBeige = Color(0xFFF3EAD5);
  static const Color _mutedGold = Color(0xFF9C8D67);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _nativeGoogleSignIn() async {
    if (_currentLoadingType != LoginType.none) return;
    setState(() => _currentLoadingType = LoginType.google);

    try {
      const webClientId =
          '979476390296-mpkperh9dusiodj3a9it39a43ggmlkg8.apps.googleusercontent.com';
      const iosClientId =
          '979476390296-at2ccodt70stjduoe29k8tptgc5isih4.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('預期外的錯誤：放棄 Google 登入。');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw AuthException('找不到 ID Token。');
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ShowRoomPage()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 登入失敗: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _currentLoadingType = LoginType.none);
    }
  }

  Future<void> _handleWebOAuth(OAuthProvider provider, LoginType type) async {
    if (_currentLoadingType != LoginType.none) return;
    setState(() => _currentLoadingType = type);

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登入失敗: ${error.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _currentLoadingType = LoginType.none);
    }
  }

  void _showSignUpSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            setState(() {
              _isSignUpMode = false;
            });
          }
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            // border: Border.all(color: _gold, width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('註冊成功！', style: TextStyle(fontWeight: FontWeight.bold, color: _gold)),
            ],
          ),
          content: const Text(
            '現在請至信箱收取驗證信\n\n（本視窗將於 3 秒後自動返回）',
            style: TextStyle(fontSize: 16, color: _textBeige),
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            // border: Border.all(color: _gold, width: 1),
          ),
          title: const Text('重設密碼', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('請輸入您的 Email，我們將向您發送重設密碼的郵件。', style: TextStyle(color: _textBeige)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: _textBeige),
                  decoration: InputDecoration(
                    labelText: '電子信箱',
                    labelStyle: const TextStyle(color: _mutedGold),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0x44D4AF37)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: _gold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email, color: _gold),
                  ),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? '請輸入電子信箱' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
              onPressed: () async {
                if (!dialogFormKey.currentState!.validate()) return;

                try {
                  await Supabase.instance.client.auth.resetPasswordForEmail(
                    resetEmailController.text.trim(),
                    redirectTo: 'io.supabase.flutter://login-callback/',
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('重設密碼信件已發送，請檢查您的信箱')),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('發生錯誤: ${error.toString()}')),
                    );
                  }
                }
              },
              child: const Text('發送重設信', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentLoadingType != LoginType.none) return;

    setState(() => _currentLoadingType = LoginType.email);
    final supabase = Supabase.instance.client;

    try {
      if (_isSignUpMode) {
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          emailRedirectTo: 'io.supabase.flutter://login-callback/',
        );

        if (response.user != null) {
          _showSignUpSuccessDialog();
        }
      } else {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (response.session != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ShowRoomPage()),
            );
          }
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        String errorMessage = '發生驗證錯誤，請稍後再試。';

        if (error.message == 'Invalid login credentials') {
          errorMessage = '電子信箱或密碼錯誤，請重新輸入。';
        } else if (error.message == 'Email not confirmed') {
          errorMessage = '您的電子信箱尚未驗證，請先至信箱收取驗證信。';
        } else if (error.message.contains('rate limit')) {
          errorMessage = '登入嘗試次數過多，請稍後再試。';
        } else {
          errorMessage = '驗證失敗: ${error.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.grey[900],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('系統錯誤: ${error.toString()}'),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _currentLoadingType = LoginType.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnyButtonLoading = _currentLoadingType != LoginType.none;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isSignUpMode ? 'Revhub · 註冊' : 'Revhub · 登入',
          style: const TextStyle(
            color: _gold,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/login_back_ground.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 頂部金色跑車圖示與標題
                  const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 68,
                    color: _gold,
                  ),
                  const Text(
                    'Revhub',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: _gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUpMode ? '加入專屬社群 · 從這裡開始' : '探索夢想座駕 · 從這裡開始',
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textBeige,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 半透明奢華黑金卡片表單
                  Container(
                    padding: const EdgeInsets.all(22.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(221, 22, 22, 21), // 深邃暗金基底透明色
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0x44D4AF37), // 細緻金邊線
                        width: 1.2,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 電子郵件輸入框
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isAnyButtonLoading,
                            style: const TextStyle(color: _textBeige),
                            cursorColor: _gold,
                            decoration: _buildInputDecoration(
                              hintText: '電子郵箱',
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: (val) =>
                                (val == null || val.isEmpty) ? '請輸入電子郵箱' : null,
                          ),
                          const SizedBox(height: 16),

                          // 密碼輸入框
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            enabled: !isAnyButtonLoading,
                            style: const TextStyle(color: _textBeige),
                            cursorColor: _gold,
                            decoration: _buildInputDecoration(
                              hintText: '密碼',
                              prefixIcon: Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _mutedGold,
                                  size: 20,
                                ),
                                onPressed: isAnyButtonLoading
                                    ? null
                                    : () => setState(() => _isObscure = !_isObscure),
                              ),
                            ),
                            validator: (val) => (val == null || val.length < 6)
                                ? '密碼長度需至少 6 位數'
                                : null,
                          ),

                          // 忘記密碼
                          if (!_isSignUpMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: isAnyButtonLoading ? null : _showForgotPasswordDialog,
                                  child: const Text(
                                    '忘記密碼？',
                                    style: TextStyle(color: _mutedGold, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 22),

                          // 金色漸層登入/註冊主按鈕
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_goldLight, _goldDark],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: _goldDark.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: isAnyButtonLoading ? null : _handleSubmit,
                              child: _currentLoadingType == LoginType.email
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      _isSignUpMode ? '註冊' : '登入',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 分隔線列
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Color(0x22D4AF37), thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '或使用以下方式登入',
                                  style: TextStyle(color: _mutedGold, fontSize: 12),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0x22D4AF37), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Google 膠囊按鈕
                          _buildSocialButton(
                            text: '使用 Google 帳戶登入',
                            isLoading: _currentLoadingType == LoginType.google,
                            backgroundColor: const Color(0x1FFFFFFF),
                            borderColor: const Color(0x22FFFFFF),
                            iconWidget: const Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                fontFamily: 'Times New Roman',
                              ),
                            ),
                            onPressed: _nativeGoogleSignIn,
                          ),
                          const SizedBox(height: 12),

                          // Facebook 膠囊按鈕
                          _buildSocialButton(
                            text: '使用 Facebook 帳戶登入',
                            isLoading: _currentLoadingType == LoginType.facebook,
                            backgroundColor: const Color(0xFF18233C),
                            borderColor: const Color(0x11FFFFFF),
                            iconWidget: const Icon(Icons.facebook, color: Colors.white, size: 20),
                            onPressed: isAnyButtonLoading
                                ? () {}
                                : () => _handleWebOAuth(OAuthProvider.facebook, LoginType.facebook),
                          ),
                          const SizedBox(height: 12),

                          // GitHub 膠囊按鈕 (外觀極簡化，完美貼合附圖中 Apple 按鈕的奢華黑灰調)
                          _buildSocialButton(
                            text: '使用 GitHub 帳戶登入',
                            isLoading: _currentLoadingType == LoginType.github,
                            backgroundColor: const Color(0x15FFFFFF),
                            borderColor: const Color(0x1AFFFFFF),
                            iconWidget: const Icon(Icons.code_rounded, color: Colors.white, size: 18),
                            onPressed: isAnyButtonLoading
                                ? () {}
                                : () => _handleWebOAuth(OAuthProvider.github, LoginType.github),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 底部切換 登入/註冊 連結
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUpMode ? '已經有帳號？' : '還沒有帳號？',
                        style: const TextStyle(color: _textBeige, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: isAnyButtonLoading
                            ? null
                            : () => setState(() => _isSignUpMode = !_isSignUpMode),
                        child: Text(
                          _isSignUpMode ? '立即登入' : '立即註冊',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 封裝輸入框外觀樣式
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _mutedGold, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: _gold, size: 22),
      filled: true,
      fillColor: const Color(0x22000000),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      errorStyle: const TextStyle(color: Colors.redAccent),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x44D4AF37), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _gold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // 封裝膠囊型社群按鈕
  Widget _buildSocialButton({
    required String text,
    required bool isLoading,
    required Color backgroundColor,
    required Color borderColor,
    required Widget iconWidget,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}