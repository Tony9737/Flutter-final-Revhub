import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import '../../features/car_home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

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
  bool _isLoading = false;
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _nativeGoogleSignIn() async {
    setState(() => _isLoading = true);
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

      // 將憑證傳給 Supabase 換取登入 Session
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.session != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google 原生登入成功！')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 登入失敗: ${error.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // 新增：忘記密碼彈出視窗與邏輯
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

    setState(() => _isLoading = true);
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('登入成功！')));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('發生錯誤: ${error.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('車輛展示平台 - 登入'), centerTitle: true),
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
                          // 1. Email 輸入框
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: '電子信箱',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) =>
                                (val == null || val.isEmpty) ? '請輸入電子信箱' : null,
                          ),
                          const SizedBox(height: 16),

                          // 2. 密碼輸入框
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _isObscure,
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
                                onPressed: () {
                                  setState(() => _isObscure = !_isObscure);
                                },
                              ),
                            ),
                            validator: (val) => (val == null || val.length < 6)
                                ? '密碼長度需至少 6 位數'
                                : null,
                          ),

                          // 忘記密碼按鈕 (只在「登入模式」下顯示)
                          if (!_isSignUpMode)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text(
                                  '忘記密碼？',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          if (_isSignUpMode) const SizedBox(height: 20),

                          // 3. 登入 / 註冊 按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      _isSignUpMode ? '註冊' : '登入',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),

                          // 4. 切換 登入/註冊 模式
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUpMode = !_isSignUpMode;
                              });
                            },
                            child: Text(
                              _isSignUpMode ? '已經有帳號？前往登入' : '沒有帳號？前往註冊',
                            ),
                          ),

                          const Divider(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  ) // 載入中狀態
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
                          const SizedBox(height: 10),

                          // 5. 社群登入按鈕
                          SupaSocialsAuth(
                            socialProviders: const [
                              OAuthProvider.facebook,
                              OAuthProvider.twitter,
                            ],
                            redirectUrl:
                                'io.supabase.flutter://login-callback/',
                            onSuccess: (session) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('社群登入成功！')),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                            onError: (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('發生錯誤: ${error.toString()}'),
                                ),
                              );
                            },
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
