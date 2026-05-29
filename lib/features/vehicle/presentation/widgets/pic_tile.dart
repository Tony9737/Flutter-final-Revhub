import 'package:flutter/material.dart';
import 'package:flutter_final_revhub/features/vehicle/presentation/pages/vehicle_intro_page.dart';
import 'package:flutter_final_revhub/features/vehicle/domain/entities/vehicle.dart';

class PicTile extends StatelessWidget {
  final Vehicle vehicle;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const PicTile({
    super.key,
    required this.vehicle,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final coverBase = vehicle.media.coverPath;
    final coverPath = vehicle.media.isGifCover
        ? '$coverBase/images/cover/cover.gif'
        : '$coverBase/images/cover/cover.jpg';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleIntroPage(
              vehicle: vehicle,
              isFavorite: isFavorite,
              onToggleFavorite: onToggleFavorite,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x73D4AF37), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(<double>[
                  0.9, 0, 0, 0, 0, // 紅色通道 - 保持顏色但暗化
                  0, 0.9, 0, 0, 0, // 綠色通道 - 保持顏色但暗化
                  0, 0, 0.8, 0, 0, // 藍色通道 - 暗化較多增加暖感
                  0, 0, 0, 1, 0, // Alpha 通道 - 保持不變
                ]),
                child: Image.asset(
                  coverPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1A1711),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.directions_car_filled,
                        color: Color(0xFFD4AF37),
                      ),
                    );
                  },
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x05000000),
                    Color(0x38000000),
                    Color(0x8A000000),
                  ],
                  stops: [0.35, 0.72, 1],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    vehicle.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF9F1DF),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    vehicle.spec.vehicleType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCFBD90),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
