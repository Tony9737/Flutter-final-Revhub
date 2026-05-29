import 'package:flutter/material.dart';
import 'package:flutter_final_revhub/features/vehicle/presentation/pages/vehicle_intro_page.dart';
import 'package:flutter_final_revhub/vehicle_data.dart';
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
  static const Color _textMain = Color(0xFFF3EAD5);
  static const Color _textSub = Color(0xFFD8C9A1);

  @override
  Widget build(BuildContext context) {
    // 根據頁面模式取得要顯示的車輛清單
    final filteredVehicles =
        vehicles ??
        mockVehicles.where((v) => v.spec.country == country).toList();

    // 如果該國家目前沒有車輛，顯示提示畫面
    if (filteredVehicles.isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? (country != null ? '目前沒有 $country 的車輛' : '目前沒有車輛'),
          style: const TextStyle(color: _textSub, fontSize: 16),
        ),
      );
    }

    // 使用 ListView.builder 建立列表 
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = filteredVehicles[index];

        return Card(
          color: _cardBase,
          elevation: 8,
          shadowColor: const Color(0x22000000),
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x4DD4AF37), width: 1),
          ),
          clipBehavior: Clip.antiAlias, // 讓內部的圖片也能跟著圓角裁切
          child: InkWell(
            onTap: () {
              final isFavorite = favoriteKeys.contains(
                vehicleFavoriteKey(vehicle),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VehicleIntroPage(
                    vehicle: vehicle,
                    isFavorite: isFavorite,
                    onToggleFavorite: () => onToggleFavorite(vehicle),
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左側：車輛封面圖片
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 130,
                      height: 100,
                      child: Image.asset(
                        '${vehicle.media.coverPath}/images/cover/cover.jpg',
                        fit: BoxFit.cover,
                        // 開發階段若圖片路徑不對，避免紅屏
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _cardAlt,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.directions_car,
                            color: _gold,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 右側：車輛詳細資訊 (使用 Expanded 填滿剩餘空間)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 廠牌與型號
                        Text(
                          '${vehicle.brand} ${vehicle.model}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // 引擎 Spec
                        Row(
                          children: [
                            const Icon(Icons.settings, size: 14, color: _gold),
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
                        const SizedBox(height: 4),

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
                        const SizedBox(height: 4),
                        // 國家 (排在最下面並凸顯顏色)
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
