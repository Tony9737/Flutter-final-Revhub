import 'package:flutter/material.dart';
import '../pages/vehicle_intro_page.dart';
import '../../domain/entities/vehicle.dart';

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
    // 🔥 核心修正：對接 Supabase 雲端寫入的 posts.cover_path 長網址
    final String coverUrl = vehicle.coverPath;

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
            // 🖼️ 修正：從 Image.asset 改為 Image.network 讀取雲端網址
            coverUrl.isNotEmpty
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1F1F1F),
                      child: const Icon(Icons.directions_car, color: Colors.grey, size: 40),
                    ),
                  )
                : Container(color: const Color(0xFF1F1F1F)),
                
            // 漸層陰影遮罩
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
            // 愛心收藏按鈕
            PositionfulHeart(isFavorite: isFavorite, onTap: onToggleFavorite),
            // 文字資訊
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
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

// 抽取愛心小元件保持代碼整潔
class PositionfulHeart extends StatelessWidget {
  const PositionfulHeart({super.key, required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? const Color(0xFFD4AF37) : Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}