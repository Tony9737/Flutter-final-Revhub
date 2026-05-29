import 'package:flutter/material.dart';
import '../widgets/pic_tile.dart';
import 'package:flutter_final_revhub/vehicle_data.dart'; // 暫時保留 mock 資料，直到你改好 API
import '../../domain/entities/vehicle.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.favoriteKeys,
    required this.onToggleFavorite,
    required this.selectedCountries,
  });

  final Set<String> favoriteKeys;
  final ValueChanged<Vehicle> onToggleFavorite;
  final Set<String> selectedCountries;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  List<Vehicle> _shuffledVehicles = const [];
  TabController? _tabController;
  int _shuffleVersion = 0;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _shuffleVehicles();
  }

  @override
  void didUpdateWidget(PreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當 selectedCountries 改變時，重新打亂
    if (oldWidget.selectedCountries != widget.selectedCountries) {
      _shuffleVehicles();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TabController? controller;
      try {
        controller = DefaultTabController.of(context);
      } catch (_) {
        controller = null;
      }
      if (_tabController == controller) return;

      _tabController?.removeListener(_handleTabChange);
      _tabController = controller;
      if (controller != null) {
        _lastTabIndex = controller.index;
        _tabController?.addListener(_handleTabChange);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    final controller = _tabController;
    if (controller == null) {
      return;
    }

    final currentIndex = controller.index;
    if (currentIndex == _lastTabIndex) {
      return;
    }

    _lastTabIndex = currentIndex;
    if (currentIndex == 0 && mounted) {
      _shuffleVehicles();
    }
  }

  void _shuffleVehicles() {
    final next =
        mockVehicles
            .where((v) => widget.selectedCountries.contains(v.spec.country))
            .toList()
          ..shuffle();
    setState(() {
      _shuffledVehicles = next;
      _shuffleVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1250
                    ? 5
                    : width >= 980
                    ? 4
                    : width >= 680
                    ? 3
                    : 2;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.985, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: GridView.builder(
                    key: ValueKey('grid-$_shuffleVersion'),
                    itemCount: _shuffledVehicles.length,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: width < 680 ? 0.78 : 0.74,
                    ),
                    itemBuilder: (context, index) {
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
