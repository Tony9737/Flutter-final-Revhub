import 'package:flutter/material.dart';
import 'package:flutter_final_revhub/features/vehicle/presentation/pages/vehicle_intro_page.dart';
import 'package:flutter_final_revhub/features/vehicle/domain/entities/vehicle.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard(
    this.country, {
    super.key,
    required this.favoriteKeys,
    required this.onToggleFavorite,
  }) : vehicles = null,
       emptyMessage = null;

  const VehicleCard.fromVehicles({
    super.key,
    required this.vehicles,
    required this.favoriteKeys,
    required this.onToggleFavorite,
    this.emptyMessage,
  }) : country = null;

  final String? country;
  final List<Vehicle>? vehicles;
  final String? emptyMessage;
  final Set<String> favoriteKeys;
  final ValueChanged<Vehicle> onToggleFavorite;
  
  static const Color _cardBase = Color(0xFF17130E);
  static const Color _cardAlt = Color(0xFF0F0C08);
  static const Color _gold = Color(0xFFD4AF37);
  // static const Color _textMain = Color(0xFFF3EAD5);
  static const Color _textSub = Color(0xFFD8C9A1);

  @override
  Widget build(BuildContext context) {
    // 💡 核心修正：我們在 show_room_page 中已經使用 .fromVehicles 建構子把單一 API 車款包成 List 傳入
    final displayVehicles = vehicles ?? [];

    if (displayVehicles.isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? '暫無資料',
          style: const TextStyle(color: _textSub),
        ),
      );
    }

    return PageView.builder(
      itemCount: displayVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = displayVehicles[index];
        final isAlt = index % 2 == 1;
        final favKey = '${vehicle.brand}-${vehicle.model}';
        final isFav = favoriteKeys.contains(favKey);

        return Card(
          color: isAlt ? _cardAlt : _cardBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: _gold.withValues(alpha: isAlt ? 0.1 : 0.2),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleIntroPage(
                    vehicle: vehicle,
                    isFavorite: isFav,
                    onToggleFavorite: () => onToggleFavorite(vehicle),
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🖼️ 上方車輛大圖區區塊
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                     ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        // 直接丟入 vehicle.coverPath，不要做任何字串拼接！
                        child: vehicle.coverPath.isNotEmpty
                            ? Image.network(
                                vehicle.coverPath, // 👈 這裡直接放欄位
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // print("❌ 圖片載入失敗網址為: ${vehicle.coverPath}"); // 方便你 Debug 檢查
                                  return Container(
                                    color: const Color(0xFF231E18),
                                    child: const Icon(Icons.directions_car, color: _textSub, size: 50),
                                  );
                                },
                              )
                            : Container(color: const Color(0xFF231E18)),
                      ),
                      // 漸層陰影遮罩
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 品牌標籤與愛心按鈕
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vehicle.brand.toUpperCase(),
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => onToggleFavorite(vehicle),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: _gold,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 車款名稱（壓在大圖下方）
                      Positioned(
                        left: 20,
                        bottom: 16,
                        right: 20,
                        child: Text(
                          vehicle.model,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 📝 下方規格基本數據區塊
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 價格與幣別
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ESTIMATED PRICE',
                              style: TextStyle(
                                color: Color(0xFF7A6F5D),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${vehicle.currency} ${(vehicle.price / 10000).toStringAsFixed(0)}萬',
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF2E261D), height: 20),
                        
                        // 引擎規格
                        Row(
                          children: [
                            const Icon(Icons.settings_input_component, size: 14, color: _gold),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vehicle.spec.engine,
                                style: const TextStyle(
                                  color: _textSub,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 馬力
                        Row(
                          children: [
                            const Icon(Icons.speed, size: 14, color: _gold),
                            const SizedBox(width: 4),
                            Text(
                              '${vehicle.spec.horsepower} hp',
                              style: const TextStyle(
                                color: _textSub,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // 國家來源
                        Row(
                          children: [
                            const Icon(Icons.public, size: 14, color: _gold),
                            const SizedBox(width: 4),
                            Text(
                              vehicle.spec.country,
                              style: const TextStyle(
                                color: _textSub,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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