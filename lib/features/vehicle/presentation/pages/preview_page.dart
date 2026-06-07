import 'package:flutter/material.dart';
import '../widgets/pic_tile.dart';
import '../../domain/entities/vehicle.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.favoriteKeys,
    required this.onToggleFavorite,
    required this.selectedCountries,
    required this.allApiVehicles, // 🔥 接收從 ShowRoomPage 傳進來的真實雲端 API 資料
  });

  final Set<String> favoriteKeys;
  final ValueChanged<Vehicle> onToggleFavorite;
  final Set<String> selectedCountries;
  final List<Vehicle> allApiVehicles; // 🔥 宣告參數

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  List<Vehicle> _shuffledVehicles = const [];
  int _shuffleVersion = 0;

  @override
  void initState() {
    super.initState();
    _shuffleVehicles();
  }

  @override
  void didUpdateWidget(PreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當外部的篩選國家改變，或是 API 重新整理拿到新資料時，重新觸發打亂過濾
    if (oldWidget.selectedCountries != widget.selectedCountries ||
        oldWidget.allApiVehicles != widget.allApiVehicles) {
      _shuffleVehicles();
    }
  }

  // 🔀 核心修改：移除對 mockVehicles 的依賴，直接對 API 拿到的資料做篩選與打亂
  void _shuffleVehicles() {
    final next = widget.allApiVehicles
        .where((Vehicle v) => widget.selectedCountries.contains(v.spec.country))
        .toList()
      ..shuffle();
    setState(() {
      _shuffledVehicles = next;
      _shuffleVersion++;
    });
  }

  String vehicleFavoriteKey(Vehicle vehicle) =>
      '${vehicle.brand}-${vehicle.model}';

  @override
  Widget build(BuildContext context) {
    if (_shuffledVehicles.isEmpty) {
      return const Center(
        child: Text(
          '無符合該國家的車款圖片',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true,
      child: CustomScrollView(
        key: PageStorageKey<String>('preview_scroll_$_shuffleVersion'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                childCount: _shuffledVehicles.length,
                (context, index) {
                  final vehicle = _shuffledVehicles[index];
                  final delayUnit = index % 7;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(
                      '${vehicle.brand}-${vehicle.model}-$_shuffleVersion',
                    ),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                      milliseconds: 260 + (delayUnit * 55),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 18),
                          child: child,
                        ),
                      );
                    },
                    child: PicTile(
                      vehicle: vehicle,
                      isFavorite: widget.favoriteKeys.contains(
                        vehicleFavoriteKey(vehicle),
                      ),
                      onToggleFavorite: () =>
                          widget.onToggleFavorite(vehicle),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}