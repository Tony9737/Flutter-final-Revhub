import 'package:flutter/material.dart';
import '../widgets/pic_tile.dart';
import '../../domain/entities/vehicle.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.favoriteKeys,
    required this.onToggleFavorite,
    required this.selectedCountries,
    required this.allApiVehicles, 
    this.storageKeyPrefix = 'preview',
    this.emptyMessage = '無符合該國家的車款圖片',
  });

  final Set<String> favoriteKeys;
  final ValueChanged<Vehicle> onToggleFavorite;
  final Set<String> selectedCountries;
  final List<Vehicle> allApiVehicles; 
  final String storageKeyPrefix;
  final String emptyMessage;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> with AutomaticKeepAliveClientMixin {
  List<Vehicle> _shuffledVehicles = const [];
  int _shuffleVersion = 0;

  // 2. 必須複寫 wantKeepAlive，並回傳 true
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _shuffleVehicles();
  }

  @override
  void didUpdateWidget(PreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCountries != widget.selectedCountries ||
        _signature(oldWidget.allApiVehicles) != _signature(widget.allApiVehicles) ||
        oldWidget.storageKeyPrefix != widget.storageKeyPrefix) {
      _shuffleVehicles();
    }
  }

  String _signature(List<Vehicle> vehicles) {
    return vehicles
        .map((vehicle) => '${vehicle.brand}-${vehicle.model}-${vehicle.spec.country}')
        .join('|');
  }

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
    return NotificationListener<ScrollNotification>(
      // ✦ 核心修改：改成 false，允許滾動事件向上傳遞，外層的 RefreshIndicator 才能感應到下拉！
      onNotification: (_) => false,
      child: CustomScrollView(
        key: PageStorageKey<String>(
          '${widget.storageKeyPrefix}_scroll_$_shuffleVersion',
        ),
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
          if (_shuffledVehicles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  widget.emptyMessage,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}