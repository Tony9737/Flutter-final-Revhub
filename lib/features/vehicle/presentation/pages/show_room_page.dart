import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'preview_page.dart';
import '../widgets/chrome_layout.dart';
import '../widgets/search_section.dart';
import '../widgets/vehicle_card.dart';
import '../../domain/entities/vehicle.dart';
import '../../../auth/presentation/login_screen.dart';

import '../../data/datasource/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../../../core/network/api_client.dart';

const Color _gold = Color(0xFFD4AF37);

class ShowRoomPage extends StatefulWidget {
  const ShowRoomPage({super.key});

  @override
  State<ShowRoomPage> createState() => _ShowRoomPageState();
}

class _ShowRoomPageState extends State<ShowRoomPage>
    with SingleTickerProviderStateMixin {
  final Set<String> _favorites = <String>{};
  late TabController _tabController;
  int _currentTabIndex = 0;

  late Future<List<Vehicle>> _vehiclesFuture;
  Set<String> _selectedCountries = <String>{};
  bool _isCountriesInitialized = false;

  late final VehicleRepositoryImpl _vehicleRepository;

  String _getVehicleKey(Vehicle vehicle) => '${vehicle.brand}-${vehicle.model}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    final apiClient = ApiClient();
    final remoteDataSource = VehicleRemoteDataSource(apiClient: apiClient);
    _vehicleRepository = VehicleRepositoryImpl(remoteDataSource: remoteDataSource);

    _loadData();
  }

  void _loadData({bool forceRefresh = false}) {
    setState(() {
      _vehiclesFuture = _vehicleRepository.getVehiclePosts(forceRefresh: forceRefresh);
    });
  }

  Future<void> _refreshVehicles() async {
    _loadData(forceRefresh: true);
    try {
      await _vehiclesFuture;
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFavorite(Vehicle vehicle) {
    setState(() {
      final key = _getVehicleKey(vehicle);
      if (_favorites.contains(key)) {
        _favorites.remove(key);
      } else {
        _favorites.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF100D0A),
          border: Border(top: BorderSide(color: Color(0x22D4AF37), width: 1)),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
                _tabController.animateTo(index);
              },
              backgroundColor: Colors.transparent,
              selectedItemColor: _gold,
              unselectedItemColor: const Color(0xFF9C8D67),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 26),
                  activeIcon: Icon(Icons.home_rounded, size: 26),
                  label: '探索',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.layers_outlined, size: 26),
                  activeIcon: Icon(Icons.layers_rounded, size: 26),
                  label: '抽卡',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded, size: 26),
                  label: '搜尋',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline_rounded, size: 26),
                  activeIcon: Icon(Icons.favorite_rounded, size: 26),
                  label: '收藏',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/showroom_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF140F0A).withValues(alpha: 0.16),
                const Color(0xFF0A0806).withValues(alpha: 0.40),
              ],
            ),
          ),
          child: SafeArea(
            child: FutureBuilder<List<Vehicle>>(
              future: _vehiclesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError && !snapshot.hasData) {
                  return ChromeLayout(
                    vehicleCount: 0,
                    currentTabIndex: _currentTabIndex,
                    onLogout: () => _logout(context),
                    onFilterPressed: null,
                    body: Center(child: Text('載入失敗：${snapshot.error}', style: const TextStyle(color: Colors.white))),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return ChromeLayout(
                    vehicleCount: 0,
                    currentTabIndex: _currentTabIndex,
                    onLogout: () => _logout(context),
                    onFilterPressed: null,
                    body: const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 3.5)),
                  );
                }

                final allVehicles = snapshot.data ?? <Vehicle>[];

                if (!_isCountriesInitialized && allVehicles.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _isCountriesInitialized) return;
                    setState(() {
                      _selectedCountries = allVehicles.map((v) => v.spec.country).toSet();
                      _isCountriesInitialized = true;
                    });
                  });
                }

                final filteredVehicles = allVehicles.where((v) => _selectedCountries.contains(v.spec.country)).toList();
                final favoriteVehicles = allVehicles.where((v) => _favorites.contains(_getVehicleKey(v))).toList();

                return ChromeLayout(
                  vehicleCount: allVehicles.length,
                  currentTabIndex: _currentTabIndex,
                  onLogout: () => _logout(context),
                  onFilterPressed: allVehicles.isEmpty ? null : () => _showFilterDialog(allVehicles),
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // Index 0: 探索
                      RefreshIndicator(
                        color: _gold,
                        backgroundColor: const Color(0xFF161616),
                        onRefresh: _refreshVehicles,
                        child: PreviewPage(
                          favoriteKeys: _favorites,
                          onToggleFavorite: _toggleFavorite,
                          selectedCountries: _selectedCountries,
                          allApiVehicles: allVehicles,
                          storageKeyPrefix: 'explore',
                        ),
                      ),
                      
                      // Index 1: 抽卡
                      RefreshIndicator(
                        color: _gold,
                        backgroundColor: const Color(0xFF161616),
                        onRefresh: _refreshVehicles,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: constraints.maxHeight,
                                child: filteredVehicles.isEmpty
                                    ? const Center(child: Text('無符合該國家的車款', style: TextStyle(color: Colors.white70)))
                                    : VehicleCard.fromVehicles(
                                        vehicles: List<Vehicle>.from(filteredVehicles)..shuffle(),
                                        favoriteKeys: _favorites,
                                        onToggleFavorite: _toggleFavorite,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Index 2: 搜尋 (直接導入我們剛才分開的自訂元件)
                      SearchSection(
                        allVehicles: allVehicles,
                        favoriteKeys: _favorites,
                        onToggleFavorite: _toggleFavorite,
                      ),

                      // Index 3: 收藏
                      RefreshIndicator(
                        color: _gold,
                        backgroundColor: const Color(0xFF161616),
                        onRefresh: _refreshVehicles,
                        child: PreviewPage(
                          favoriteKeys: _favorites,
                          onToggleFavorite: _toggleFavorite,
                          selectedCountries: favoriteVehicles.map((v) => v.spec.country).toSet(),
                          allApiVehicles: favoriteVehicles,
                          storageKeyPrefix: 'favorites',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showFilterDialog(List<Vehicle> allVehicles) {
    final availableCountries = allVehicles.map((v) => v.spec.country).toSet().toList()..sort();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161616),
              title: const Text('篩選國家', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableCountries.map((c) {
                    final isChecked = _selectedCountries.contains(c);
                    return CheckboxListTile(
                      title: Text(c, style: const TextStyle(color: Color(0xFFF3EAD5))),
                      value: isChecked,
                      activeColor: _gold,
                      checkColor: Colors.black,
                      onChanged: (v) {
                        setStateSB(() {
                          setState(() {
                            final updated = Set<String>.from(_selectedCountries);
                            if (v!) { updated.add(c); } else { updated.remove(c); }
                            _selectedCountries = updated;
                          });
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('關閉', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}