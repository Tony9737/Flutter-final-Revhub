import 'package:flutter/material.dart';
import 'header_icon_button.dart';

class ChromeLayout extends StatelessWidget {
  const ChromeLayout({
    super.key,
    required this.vehicleCount,
    required this.currentTabIndex,
    required this.onLogout,
    required this.onFilterPressed,
    required this.body,
    required this.onSettingsPressed, // ✦ 新增：將點擊設定事件傳進來
  });

  final int vehicleCount;
  final int currentTabIndex;
  final Future<void> Function() onLogout;
  final VoidCallback? onFilterPressed;
  final Widget body;
  final VoidCallback onSettingsPressed; // ✦ 新增

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // ✦ 新增：靠左對齊的設定按鈕 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      HeaderIconButton(
                        icon: Icons.settings_outlined, // 齒輪圖標
                        onPressed: onSettingsPressed,
                      ),
                    ],
                  ),
                  
                  // 原本靠右對齊的登出按鈕 Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      HeaderIconButton(
                        icon: Icons.logout_rounded,
                        onPressed: onLogout,
                      ),
                    ],
                  ),
                  
                  // 原本置中的標題 Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Revhub',
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x26443312),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0x88D4AF37),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$vehicleCount Cars',
                          style: const TextStyle(
                            color: Color(0xFFF1E3C0),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              body,
              if (currentTabIndex == 0 || currentTabIndex == 1)
                Positioned(
                  right: 18,
                  bottom: 18,
                  child: FloatingActionButton(
                    onPressed: onFilterPressed,
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.filter_list),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}