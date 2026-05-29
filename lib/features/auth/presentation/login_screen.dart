import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _nativeGoogleSignIn() async {
    // 只有在沒有任何東西在載入時才允許點擊，並設為 google 載入中
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

  // web 版的 OAuth 登入（Facebook、GitHub）
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

  // 註冊成功的彈出視窗
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('註冊成功！', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            '現在請至信箱收取驗證信\n\n（本視窗將於 3 秒後自動返回）',
            style: TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }

  // 忘記密碼彈出視窗與邏輯
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重設密碼'),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('請輸入您的 Email，我們將向您發送重設密碼的郵件。'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '電子信箱',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
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
              child: const Text('取消'),
            ),
            ElevatedButton(
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
              child: const Text('發送重設信'),
            ),
          ],
        );
      },
    );
  }

  // 處理 Email 登入與註冊
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
      // 專門捕捉 Supabase 驗證相關的異常
      if (mounted) {
        String errorMessage = '發生驗證錯誤，請稍後再試。';

        // 根據 Supabase 回傳的英文訊息轉成繁體中文
        if (error.message == 'Invalid login credentials') {
          errorMessage = '電子信箱或密碼錯誤，請重新輸入。';
        } else if (error.message == 'Email not confirmed') {
          errorMessage = '您的電子信箱尚未驗證，請先至信箱收取驗證信。';
        } else if (error.message.contains('rate limit')) {
          errorMessage = '登入嘗試次數過多，請稍後再試。';
        } else {
          // 如果有其他未條列的 Auth 錯誤，就顯示 Supabase 的原始英文訊息
          errorMessage = '登入失敗: ${error.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } catch (error) {
      // 捕捉非 Supabase 的一般錯誤
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
    // 便利變數：只要不是 none，就代表當前有按鈕正在忙碌中
    final isAnyButtonLoading = _currentLoadingType != LoginType.none;

    return Scaffold(
      appBar: AppBar(title: const Text('Revhub - 登入'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  '歡迎來到車友社群',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Email 輸入框
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isAnyButtonLoading, // 載入中禁用輸入
                            decoration: const InputDecoration(
                              labelText: '電子信箱',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) =>
                                (val == null || val.isEmpty) ? '請輸入電子信箱' : null,
                          ),
                          const SizedBox(height: 16),

                          // 密碼輸入框
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscure,
                            enabled: !isAnyButtonLoading, // 載入中禁用輸入
                            decoration: InputDecoration(
                              labelText: '密碼',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: isAnyButtonLoading
                                    ? null
                                    : () => setState(
                                        () => _isObscure = !_isObscure,
                                      ),
                              ),
                            ),
                            validator: (val) => (val == null || val.length < 6)
                                ? '密碼長度需至少 6 位數'
                                : null,
                          ),

                          // 忘記密碼按鈕
                          if (!_isSignUpMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isAnyButtonLoading
                                    ? null
                                    : _showForgotPasswordDialog,
                                child: const Text(
                                  '忘記密碼？',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          if (_isSignUpMode) const SizedBox(height: 20),

                          // 登入 / 註冊 按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: isAnyButtonLoading
                                  ? null
                                  : _handleSubmit,
                              child: _currentLoadingType == LoginType.email
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isSignUpMode ? '註冊' : '登入',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),

                          // 切換 登入/註冊 模式
                          TextButton(
                            onPressed: isAnyButtonLoading
                                ? null
                                : () => setState(
                                    () => _isSignUpMode = !_isSignUpMode,
                                  ),
                            child: Text(
                              _isSignUpMode ? '已經有帳號？前往登入' : '沒有帳號？前往註冊',
                            ),
                          ),

                          const Divider(height: 30),

                          // Google 登入按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _currentLoadingType == LoginType.google
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: SignInButton(
                                      Buttons.google,
                                      text: "使用 Google 帳戶登入",
                                      onPressed: _nativeGoogleSignIn,
                                      padding: EdgeInsets.zero,
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Facebook 登入按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _currentLoadingType == LoginType.facebook
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: SignInButton(
                                      Buttons.facebook,
                                      text: "使用 Facebook 帳戶登入",
                                      onPressed: isAnyButtonLoading
                                          ? () {}
                                          : () => _handleWebOAuth(
                                              OAuthProvider.facebook,
                                              LoginType.facebook,
                                            ),
                                      padding: EdgeInsets.zero,
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // GitHub 登入按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _currentLoadingType == LoginType.github
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: SignInButton(
                                      Buttons.gitHub,
                                      text: "使用 GitHub 帳戶登入",
                                      onPressed: isAnyButtonLoading
                                          ? () {}
                                          : () => _handleWebOAuth(
                                              OAuthProvider.github,
                                              LoginType.github,
                                            ),
                                      padding: EdgeInsets.zero,
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
