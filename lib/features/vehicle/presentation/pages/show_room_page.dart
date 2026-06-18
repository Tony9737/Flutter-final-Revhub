import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'preview_page.dart';
import 'gacha_page.dart';
import '../widgets/chrome_layout.dart';
import '../widgets/search_section.dart';
import '../../../ai_assistant/presentation/pages/gemini_chat_page.dart';
import '../../domain/entities/vehicle.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../../core/services/audio/audio_manager.dart'; 
import '../../../../core/config/local_secrets.dart';

import '../../data/datasource/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../../../core/network/api_client.dart';
import '../../../ai_assistant/data/services/gemini_recommendation_service.dart';

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

  // 儲存 AI 篩選過後的 car_id 清單（若為 null 代表未啟用 AI 篩選）
  List<String>? _aiRecommendedIds;
  String? _aiReason; // 儲存 AI 推薦的一段話

  late final VehicleRepositoryImpl _vehicleRepository;

  final _geminiService = GeminiRecommendationService(apiKey: geminiApiKey);

  String _getVehicleKey(Vehicle vehicle) => '${vehicle.brand}-${vehicle.model}';

  @override
  void initState() {
    super.initState();
    
    // 進入展間時，自動開啟高質感背景音樂
    AudioManager.instance.startBgm();

    _tabController = TabController(length: 5, vsync: this);
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

  String convertVehiclesToAiContext(List<Vehicle> vehicles) {
    return vehicles.map((v) {
      return {
        'id': v.carID,
        'name': '${v.brand} ${v.model}',
        'type': v.spec.vehicleType,
        'country': v.spec.country,
        'engine': v.spec.engine,
        'hp': v.spec.horsepower,
        'price': v.price,
      };
    }).toList().toString();
  }

  // 彈出高質感黑金 BGM 設定控制視窗
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final audio = AudioManager.instance;
            return AlertDialog(
              backgroundColor: const Color(0xFB161412), // 呼應暗黑金屬底色
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                // border: Border.all(color: const Color(0x66D4AF37), width: 1.2),
              ),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: _gold, size: 24),
                  SizedBox(width: 10),
                  Text(
                    '系統與音效設定',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0x22D4AF37), height: 1),
                  const SizedBox(height: 16),

                  // BGM 開關
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.music_note_rounded, color: Color(0xFFF3EAD5), size: 20),
                          SizedBox(width: 8),
                          Text('背景音樂 (BGM)', style: TextStyle(color: Color(0xFFF3EAD5), fontSize: 15)),
                        ],
                      ),
                      Switch(
                        value: audio.isBgmEnabled,
                        activeColor: Colors.black,
                        activeTrackColor: _gold,
                        inactiveThumbColor: Colors.grey[400],
                        inactiveTrackColor: Colors.grey[800],
                        onChanged: (value) async {
                          await audio.toggleBgm(value);
                          setDialogState(() {}); // 實時更新 Dialog 狀態
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 曲目切換下拉選單
                  const Text('更換曲目', style: TextStyle(color: Color(0xFF9C8D67), fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x22D4AF37)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: audio.currentTrackName,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1715),
                        icon: const Icon(Icons.arrow_drop_down, color: _gold),
                        style: const TextStyle(color: Color(0xFFF3EAD5), fontSize: 14),
                        disabledHint: const Text('音樂已關閉', style: TextStyle(color: Colors.grey)),
                        items: audio.isBgmEnabled
                            ? audio.trackNames.map((String track) {
                                return DropdownMenuItem<String>(
                                  value: track,
                                  child: Text(track),
                                );
                              }).toList()
                            : null,
                        onChanged: (String? newTrack) async {
                          if (newTrack != null) {
                            await audio.changeTrack(newTrack);
                            setDialogState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 音量控制 Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('音量控制', style: TextStyle(color: Color(0xFF9C8D67), fontSize: 13)),
                      Text(
                        audio.isBgmEnabled ? '${(audio.volume * 100).toInt()}%' : '0%',
                        style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        audio.volume == 0 || !audio.isBgmEnabled
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: audio.isBgmEnabled ? const Color(0xFF9C8D67) : Colors.grey[700],
                        size: 18,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _gold,
                            inactiveTrackColor: Colors.grey[800],
                            thumbColor: const Color(0xFFE5C158),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: audio.isBgmEnabled ? audio.volume : 0.0,
                            min: 0.0,
                            max: 1.0,
                            onChanged: audio.isBgmEnabled
                                ? (value) async {
                                    await audio.setVolume(value);
                                    setDialogState(() {});
                                  }
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: _gold),
                  child: const Text('確定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAiRecommendDialog(List<Vehicle> allVehicles) {
    final textController = TextEditingController();
    bool isAiLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isAiLoading,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161616),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0x33D4AF37), width: 1),
              ),
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: _gold, size: 22),
                  SizedBox(width: 8),
                  Text('AI 智慧車輛專家推薦', style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: isAiLoading
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        CircularProgressIndicator(color: _gold),
                        SizedBox(height: 20),
                        Text('AI 正在翻閱展間清單為您挑選中...', style: TextStyle(color: Color(0xFFF3EAD5), fontSize: 14)),
                        SizedBox(height: 10),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '告訴 AI 您想要的車輛特徵（例如：「我想要馬力大於 400 匹的德系跑車」或「幫我找找適合代步且有好看的車」）',
                          style: TextStyle(color: Color(0xFF9C8D67), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: textController,
                          autofocus: true,
                          style: const TextStyle(color: Color(0xFFF3EAD5)),
                          cursorColor: _gold,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: '請輸入您的尋車需求...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFF222222),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x22D4AF37))),
                          ),
                        ),
                      ],
                    ),
              actions: isAiLoading
                  ? null
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          if (textController.text.trim().isEmpty) return;

                          setStateSB(() { isAiLoading = true; });

                          // 將當前資料庫內的所有車輛壓縮成輕量化 JSON Context
                          final contextJsonString = convertVehiclesToAiContext(allVehicles);

                          // 呼叫 Gemini 進行推理與精確匹配
                          final result = await _geminiService.fetchAiRecommendations(
                            userInput: textController.text.trim(),
                            vehiclesJsonContext: contextJsonString,
                          );

                          // 取得 AI 的推薦結果
                          if (result['success'] == true) {
                            final List<dynamic> ids = result['recommended_ids'];
                            setState(() {
                              _aiRecommendedIds = ids.map((e) => e.toString()).toList();
                              _aiReason = result['ai_reason'];
                            });
                          } else {
                            // 失敗防呆
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['ai_reason'] ?? '篩選失敗，請稍後再試')),
                            );
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('開始挑選'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                setState(() { _currentTabIndex = index; });
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
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 26), activeIcon: Icon(Icons.home_rounded, size: 26), label: '探索'),
                BottomNavigationBarItem(icon: Icon(Icons.layers_outlined, size: 26), activeIcon: Icon(Icons.layers_rounded, size: 26), label: '抽卡'),
                BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined, size: 26), activeIcon: Icon(Icons.auto_awesome_rounded, size: 26), label: 'AI聊車'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded, size: 26), label: '搜尋'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_outline_rounded, size: 26), activeIcon: Icon(Icons.favorite_rounded, size: 26), label: '收藏'),
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
                    onSettingsPressed: _showSettingsDialog, 
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return ChromeLayout(
                    vehicleCount: 0,
                    currentTabIndex: _currentTabIndex,
                    onLogout: () => _logout(context),
                    onFilterPressed: null,
                    body: const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 3.5)),
                    onSettingsPressed: _showSettingsDialog,
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

                // 複合式篩選邏輯（國家過濾 + AI 智慧推薦過濾）
                final filteredVehicles = allVehicles.where((v) {
                  final matchesCountry = _selectedCountries.contains(v.spec.country);
                  // 如果 AI 推薦清單存在，則車輛必須符合 AI 回傳的 ID 陣列
                  final matchesAi = _aiRecommendedIds == null || _aiRecommendedIds!.contains(v.carID);
                  return matchesCountry && matchesAi;
                }).toList();

                final favoriteVehicles = allVehicles.where((v) => _favorites.contains(_getVehicleKey(v))).toList();

                // 如果在 AI 篩選狀態下，上方安插一個 Banner 提示使用者，並允許一鍵重置
                Widget mainBody = TabBarView(
                  controller: _tabController,
                  children: [
                    // Index 0: 探索 (把原本的 allVehicles 改為經由 AI 篩選後的 filteredVehicles)
                    RefreshIndicator(
                      color: _gold,
                      backgroundColor: const Color(0xFF161616),
                      onRefresh: _refreshVehicles,
                      child: PreviewPage(
                        favoriteKeys: _favorites,
                        onToggleFavorite: _toggleFavorite,
                        selectedCountries: _selectedCountries,
                        allApiVehicles: filteredVehicles, // 🔥 改為 filteredVehicles 完美與 AI 連動
                        storageKeyPrefix: 'explore',
                      ),
                    ),
                    
                    // Index 1: 抽卡
                    RefreshIndicator(
                      color: _gold,
                      backgroundColor: const Color(0xFF161616),
                      onRefresh: _refreshVehicles,
                      child: GachaPage(
                        vehicles: allVehicles,             
                        favoriteKeys: _favorites,          
                        onToggleFavorite: _toggleFavorite, 
                        selectedCountries: _selectedCountries, 
                      ),
                    ),

                    // Index 2: AI聊車
                    const GeminiChatPage(),

                    // Index 3: 搜尋
                    SearchSection(
                      allVehicles: allVehicles,
                      favoriteKeys: _favorites,
                      onToggleFavorite: _toggleFavorite,
                    ),
                    
                    // Index 4: 收藏
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
                );

                // 如果啟用了 AI 篩選，則把 TabBarView 用 Column 包裹起來，上方插入 AI 專家評語與關閉按鈕
                if (_aiRecommendedIds != null) {
                  mainBody = Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xEE1A1510),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: _gold, size: 18),
                                    SizedBox(width: 6),
                                    Text('AI 推薦結果', style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _aiRecommendedIds = null;
                                      _aiReason = null;
                                    });
                                  },
                                  child: const Row(
                                    children: [
                                      Text('清除篩選', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      SizedBox(width: 4),
                                      Icon(Icons.cancel, color: Colors.grey, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_aiReason != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _aiReason!,
                                style: const TextStyle(color: Color(0xFFF3EAD5), fontSize: 13, height: 1.4),
                              ),
                            ]
                          ],
                        ),
                      ),
                      Expanded(child: mainBody),
                    ],
                  );
                }

                return ChromeLayout(
                  vehicleCount: filteredVehicles.length,
                  currentTabIndex: _currentTabIndex,
                  onLogout: () => _logout(context),
                  onFilterPressed: allVehicles.isEmpty ? null : () => _showAiRecommendDialog(allVehicles),
                  body: mainBody,
                  onSettingsPressed: _showSettingsDialog,
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

}