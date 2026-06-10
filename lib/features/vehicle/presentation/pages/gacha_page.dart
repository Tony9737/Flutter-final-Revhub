import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/vehicle.dart';
import 'vehicle_intro_page.dart'; // ✦ 修正 1：改為引入車輛詳情頁

class GachaPage extends StatefulWidget {
  final List<Vehicle> vehicles; // 傳入所有可抽取的車輛清單 (對應 allVehicles)
  final Set<String> favoriteKeys; // 傳入收藏的 Keys 紀錄
  final Function(Vehicle) onToggleFavorite; // 傳入點擊收藏的回呼函式
  final Set<String> selectedCountries; // 傳入已被選取的國家篩選清單

  const GachaPage({
    super.key, 
    required this.vehicles,
    required this.favoriteKeys,
    required this.onToggleFavorite,
    required this.selectedCountries,
  });

  @override
  State<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends State<GachaPage> with TickerProviderStateMixin {
  late AnimationController _hoverController; // 上下懸浮動畫
  late AnimationController _flipController;  // 3D 翻牌動畫
  late AnimationController _shineController; // 正面流光動畫

  Vehicle? _drawnVehicle; // 當前抽到的車
  bool _isFlipped = false; // 是否已翻開正面
  bool _isDrawing = false; // 是否正在抽卡硬直中

  @override
  void initState() {
    super.initState();
    
    // 1. 懸浮呼吸：無限循環
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // 2. 3D 翻牌：點擊時觸發
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 3. 流光：無限循環
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _flipController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  // 🎲 抽卡核心邏輯
  void _drawCard() {
    if (_isDrawing || widget.vehicles.isEmpty) return;

    setState(() {
      _isDrawing = true;
      _isFlipped = false;
    });

    _flipController.reset();

    // 隨機抽取一台車
    final random = Random();
    final targetVehicle = widget.vehicles[random.nextInt(widget.vehicles.length)];

    // 模擬盲盒在翻轉前震動或蓄力的延遲
    Future.delayed(const Duration(milliseconds: 200), () {
      _drawnVehicle = targetVehicle;
      
      // 開始執行 3D 翻轉
      _flipController.forward().then((_) {
        setState(() {
          _isFlipped = true;
          _isDrawing = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background/showroom_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🏆 頂部奢華標題
              const Text(
                'Revhub Garage',
                style: TextStyle(
                  color: Color(0xFFF2DF9A),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isFlipped ? 'CONGRATULATIONS' : 'TEST YOUR LUCK',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              // 🎴 核心動畫卡牌區
              AnimatedBuilder(
                animation: _hoverController,
                builder: (context, child) {
                  // 計算懸浮位移
                  final hoverOffset = sin(_hoverController.value * pi) * 12;
                  return Transform.translate(
                    offset: Offset(0, hoverOffset),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    if (_isFlipped && _drawnVehicle != null) {
                      // ✦ 修正 2：計算當前抽到車輛的 Favorite Key（格式與 show_room_page.dart 的 _getVehicleKey 一致）
                      final vehicleKey = '${_drawnVehicle!.brand}-${_drawnVehicle!.model}';
                      final isCarFavorite = widget.favoriteKeys.contains(vehicleKey);

                      // ✦ 修正 3：導頁至 VehicleIntroPage 傳入對應參數
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleIntroPage(
                            vehicle: _drawnVehicle!,
                            isFavorite: isCarFavorite,
                            onToggleFavorite: () {
                              widget.onToggleFavorite(_drawnVehicle!);
                            },
                          ),
                        ),
                      ).then((_) {
                        // 當使用者從車輛詳情頁按返回鍵返回時，重新整理抽卡頁面狀態以同步最愛資料
                        setState(() {});
                      });
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _flipController,
                    builder: (context, child) {
                      // 3D 視覺矩陣計算
                      final angle = _flipController.value * pi;
                      final isBack = angle < pi / 2;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012) // 關鍵：增加透視深度感
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isBack
                            ? _buildCardBack()
                            : Transform(
                                // 翻面後要把鏡像反轉回來
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: _buildCardFront(),
                              ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 🔑 奢華旋轉流光抽卡按鈕
              _buildDrawButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 🎴 卡片背面：神祕黑金盲盒狀態
  Widget _buildCardBack() {
    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景幾何裝飾線條
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33D4AF37), width: 1),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: const Color(0xAAD4AF37)),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  size: 45,
                  color: Color(0xFFF2DF9A),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'REVHUB',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'TAP TO UNLOCK',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🏎 卡片正面：抽中車輛的高奢展示面
  Widget _buildCardFront() {
    if (_drawnVehicle == null) return const SizedBox.shrink();

    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC9A227), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A227).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 3,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // 1. 車輛大圖背景
            Positioned.fill(
              child: Image.network(
                _drawnVehicle!.coverPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF222222),
                  child: const Icon(Icons.directions_car, color: Color(0xFFD4AF37), size: 50),
                ),
              ),
            ),
            // 2. 高奢漸層遮罩，確保文字清晰
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black38, Colors.transparent, Colors.black87],
                    stops: [0.0, 0.4, 0.95],
                  ),
                ),
              ),
            ),
            // 3. 頂部品牌標籤
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xDD110E06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                ),
                child: Text(
                  _drawnVehicle!.brand.toUpperCase(),
                  style: const TextStyle(color: Color(0xFFF2DF9A), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            // 4. 底部車輛資訊
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _drawnVehicle!.model,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFFD4AF37), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_drawnVehicle!.spec.horsepower} HP',
                        style: const TextStyle(color: Color(0xFFE5C14B), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        _drawnVehicle!.spec.vehicleType,
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 5. ✨ 卡片表面斜向流光層
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    final sweep = (_shineController.value * 2.4) - 1.2;
                    return Transform.translate(
                      offset: Offset(300 * sweep, 0),
                      child: OverflowBox(
                        maxHeight: 1000,
                        child: Transform.rotate(angle: -0.45, child: child),
                      ),
                    );
                  },
                  child: Align(
                    alignment: const Alignment(0.0, 0.0),
                    child: Container(
                      width: 60,
                      height: 1000,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔑 按鈕：沿用旋轉流光高奢設定
  Widget _buildDrawButton() {
    return AnimatedBuilder(
      animation: _shineController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isDrawing ? null : _drawCard,
          child: Container(
            width: 220,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              gradient: LinearGradient(
                colors: _isDrawing
                    ? [const Color(0xFF161616), const Color(0xFF262626), const Color(0xFF161616)]
                    : [const Color(0xFFC29B23), const Color(0xFFD4AF37), const Color(0xFFE5C14B)],
                transform: GradientRotation(_shineController.value * 2 * 3.14159),
              ),
              boxShadow: !_isDrawing
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ]
                  : null,
              border: Border.all(
                color: _isDrawing ? const Color(0x33C9A227) : const Color(0xFFF2DF9A),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isDrawing ? Icons.hourglass_top_rounded : Icons.auto_awesome,
                  color: _isDrawing ? const Color(0xFF888888) : const Color(0xFF110E06),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _isDrawing ? 'DRAWING...' : (_isFlipped ? 'DRAW AGAIN' : 'LAUNCH DRAW'),
                  style: TextStyle(
                    color: _isDrawing ? const Color(0xFF888888) : const Color(0xFF110E06),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}