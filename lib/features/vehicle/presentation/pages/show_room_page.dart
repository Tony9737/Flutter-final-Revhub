import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'preview_page.dart';
import '../../domain/entities/vehicle.dart';
import '../widgets/vehicle_card.dart';
import '../../../auth/presentation/login_screen.dart';

// 引入你剛寫好的 Repository 與 DataSource 層
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

  // 🔥 2. 宣告存放 API 請求的 Future 與篩選國家用的變數
  late Future<List<Vehicle>> _vehiclesFuture;
  Set<String> _selectedCountries = <String>{};
  bool _isCountriesInitialized = false; // 用於確保國家選單只在第一次載入時初始化

  // 🔥 3. 初始化我們的 API 服務連線鏈
  late final VehicleRepositoryImpl _vehicleRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    // 🔥 4. 實例化 Clean Architecture 連線層，並觸發 API 請求
    final apiClient = ApiClient();
    final remoteDataSource = VehicleRemoteDataSource(apiClient: apiClient);
    _vehicleRepository = VehicleRepositoryImpl(remoteDataSource: remoteDataSource);
    
    _loadData();
  }

  // 封裝 API 讀取方法，方便未來下拉更新 (Refresh)
  void _loadData() {
    setState(() {
      _vehiclesFuture = _vehicleRepository.getVehiclePosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFavorite(Vehicle vehicle) {
    setState(() {
      final key = '${vehicle.brand}-${vehicle.model}';
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
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Vehicle>>(
        future: _vehiclesFuture, // 📡 監聽 API 請求狀態
        builder: (context, snapshot) {
          // ⏳ 狀態一：API 還在雲端抓取資料中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          // ❌ 狀態二：API 發生錯誤
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '載入失敗：${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          // 📭 狀態三：API 成功，但資料庫空空如也
          final allVehicles = snapshot.data ?? [];
          if (allVehicles.isEmpty) {
            return const Center(
              child: Text(
                '雲端資料庫目前沒有任何汽車貼文。',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          // 📊 狀態四：API 成功拿到真實數據！動態初始化國家篩選清單
          if (!_isCountriesInitialized) {
            _selectedCountries = allVehicles
                .map((Vehicle v) => v.spec.country)
                .toSet()
                .cast<String>();
            _isCountriesInitialized = true;
          }

          // 根據國家篩選按鈕過濾後的資料庫清單，準備分發給子 UI
          final filteredVehicles = allVehicles
              .where((v) => _selectedCountries.contains(v.spec.country))
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. 頂部導覽列 AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.black,
                expandedHeight: 110,
                flexibleSpace: const FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 20, bottom: 58),
                  title: Text(
                    'REVHUB',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _loadData, // 支援手動刷新 API
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: _gold,
                            labelColor: _gold,
                            unselectedLabelColor: Colors.grey,
                            indicatorSize: TabBarIndicatorSize.label,
                            indicatorWeight: 3,
                            tabs: const [
                              Tab(text: 'PREVIEW'),
                              Tab(text: 'SHOW ROOM'),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: _gold),
                          onPressed: () => _showFilterDialog(allVehicles), // 傳入所有車輛以取得不重複國家
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 2. 內容分發區塊
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 🗂️ 視窗一：Preview 瀑布流 (將真實 API 資料與篩選國家分發進去)
                    _ThemedSection(
                      child: PreviewPage(
                        favoriteKeys: _favorites,
                        onToggleFavorite: _toggleFavorite,
                        selectedCountries: _selectedCountries,
                        allApiVehicles: allVehicles, // 🔥 傳入真實 API 資料
                      ),
                    ),
                    
                    // 🗂️ 視窗二：Show Room 大卡片滑動
                    _ThemedSection(
                      child: filteredVehicles.isEmpty
                          ? const Center(
                              child: Text(
                                '無符合該國家的車款',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : PageView.builder(
                              physics: const BouncingScrollPhysics(),
                              controller: PageController(viewportFraction: 0.85),
                              itemCount: filteredVehicles.length,
                              itemBuilder: (context, index) {
                              final vehicle = filteredVehicles[index];
                                // 傳入單一車輛，並帶入整套最原始的 favorites 集合與觸發事件
                                return VehicleCard.fromVehicles(
                                  vehicles: [vehicle], // 將單一車輛包成 List 餵給它
                                  favoriteKeys: _favorites, // 修正：傳入必要的 favoriteKeys 集合
                                  onToggleFavorite: (v) => _toggleFavorite(v),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 彈出國家篩選視窗 (從真實 API 資料動態撈取不重複的國家)
  void _showFilterDialog(List<Vehicle> allVehicles) {
    // 從現有的真實數據中，動態提取有哪些國家
    final availableCountries = allVehicles.map((v) => v.spec.country).toSet().toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161616),
              title: const Text(
                '篩選國家',
                style: TextStyle(color: _gold, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableCountries.map((c) {
                    final isChecked = _selectedCountries.contains(c);
                    return CheckboxListTile(
                      title: Text(
                        c,
                        style: const TextStyle(color: Color(0xFFF3EAD5)),
                      ),
                      value: isChecked,
                      activeColor: _gold,
                      checkColor: Colors.black,
                      onChanged: (v) {
                        setStateSB(() {
                          setState(() {
                            final updated = Set<String>.from(_selectedCountries);
                            if (v!) {
                              updated.add(c);
                            } else {
                              updated.remove(c);
                            }
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