import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 引入 Supabase

// 根據你優化後的架構，調整相對路徑
import 'preview_page.dart';
import '../../domain/entities/vehicle.dart';
import '../widgets/vehicle_card.dart';
// 預留給未來 API 的 Model
import 'package:flutter_final_revhub/vehicle_data.dart'; // 暫時保留 mock 資料，直到你改好 API

// 引入登入頁面，以便登出後跳轉
import '../../../auth/presentation/login_screen.dart';

const Color _gold = Color(0xFFD4AF37);

class ShowRoomPage extends StatefulWidget {
  const ShowRoomPage({super.key});

  @override
  State<ShowRoomPage> createState() => _ShowRoomPageState();
}

class _ShowRoomPageState extends State<ShowRoomPage>
    with SingleTickerProviderStateMixin {
  final Set<String> _favorites = <String>{};
  List<Vehicle> _shuffledVehicles = [];
  late TabController _tabController;
  int _currentTabIndex = 0;

  // 當前選取要顯示的國家，預設為全部
 late Set<String> _selectedCountries = mockVehicles
    .map((Vehicle v) => v.spec.country)
    .toSet()
    .cast<String>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    _shuffleVehicles();
  }

  void _toggleFavorite(Vehicle vehicle) {
    final key = vehicleFavoriteKey(vehicle);
    setState(() {
      if (_favorites.contains(key)) {
        _favorites.remove(key);
      } else {
        _favorites.add(key);
      }
    });
  }

  void _shuffleVehicles() {
    final List<Vehicle> baseList = List.from(mockVehicles);
    baseList.shuffle();
    _shuffledVehicles = baseList;
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            "Tony's Showroom",
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: 1.5,
            ),
          ),
          // ✨ 新增：右上角安全登出按鈕
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: _gold),
              tooltip: '登出系統',
              onPressed: () async {
                // 執行 Supabase 登出
                await Supabase.instance.client.auth.signOut();

                // 登出後切換回登入畫面，並安全地清空導航堆疊
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicatorColor: _gold,
            labelColor: _gold,
            unselectedLabelColor: const Color(0xFF6E5D3E),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: '展間首頁'),
              Tab(text: '所有車款'),
              Tab(text: '國家車款'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background/showroom_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _ThemedSection(
                child: PreviewPage(
                  favoriteKeys: _favorites,
                  onToggleFavorite: _toggleFavorite,
                  selectedCountries: _selectedCountries,
                ),
              ),
              _ThemedSection(
                child: VehicleCard.fromVehicles(
                  vehicles: _shuffledVehicles,
                  favoriteKeys: _favorites,
                  onToggleFavorite: _toggleFavorite,
                ),
              ),
              _ThemedSection(
                child: VehicleCard.fromVehicles(
                  vehicles: _shuffledVehicles
                      .where((v) => _selectedCountries.contains(v.spec.country))
                      .toList(),
                  favoriteKeys: _favorites,
                  onToggleFavorite: _toggleFavorite,
                  emptyMessage: _selectedCountries.isEmpty
                      ? '請點擊右下角篩選按鈕選取國家'
                      : null,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _currentTabIndex == 2
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF1E1911),
                shape: const CircleBorder(
                  side: BorderSide(color: _gold, width: 1),
                ),
                onPressed: _showFilterDialog,
                child: const Icon(Icons.filter_list, color: _gold),
              )
            : null,
      ),
    );
  }

  void _showFilterDialog() {
    final allCountries = mockVehicles
    .map((Vehicle v) => v.spec.country)
    .toSet()
    .cast<String>() 
    .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF120E0A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _gold, width: 1.2),
              ),
              title: const Text(
                '依國家篩選車款',
                style: TextStyle(color: _gold, fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allCountries.map((c) {
                    final isChecked = _selectedCountries.contains(c);
                    return CheckboxListTile(
                      title: Text(
                        c,
                        style: const TextStyle(color: Color(0xFFF3EAD5)),
                      ),
                      value: isChecked,
                      activeColor: _gold,
                      checkColor: Colors.black,
                      onChanged: (v) => setStateSB(() {
                        setState(() {
                          final updated = Set<String>.from(_selectedCountries);
                          if (v!) {
                            updated.add(c);
                          } else {
                            updated.remove(c);
                          }
                          _selectedCountries = updated;
                          _shuffleVehicles();
                        });
                      }),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    '關閉',
                    style: TextStyle(color: _gold, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ThemedSection extends StatelessWidget {
  const _ThemedSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.transparent, child: child);
  }
}
