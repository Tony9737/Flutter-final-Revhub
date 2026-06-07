import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_final_revhub/services/audio/audio_manager.dart';
import '../../domain/entities/vehicle.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleIntroPage extends StatefulWidget {
  final Vehicle vehicle;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const VehicleIntroPage({
    super.key,
    required this.vehicle,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<VehicleIntroPage> createState() => _VehiclePostScreenState();
}

class _VehiclePostScreenState extends State<VehicleIntroPage>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  late bool _isFavorite;
  bool _isDetailImageWide = false;
  int _currentImageIndex = 0; 
  late final AnimationController _entryController;
  late final AnimationController _shineController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late Future<List<String>> _detailImagesFuture;

  double get _detailAspectRatio => _isDetailImageWide ? 3 / 4 : 1;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _detailImagesFuture = _getSignedDetailImages();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );

    _entryController.forward();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        AudioManager.instance.resumeBgmAfterEngineSound();
      }

    });
  }

  // 🔐 動態將多張細圖路徑傳給 Supabase 批次生成含有過期 Token 的 Signed URL
  Future<List<String>> _getSignedDetailImages() async {
    final supabase = Supabase.instance.client;
    final List<String> urls = [];
    
    // 🔥 核心修正：直接使用車子的 brand 作為 Bucket 名稱（轉小寫防呆）
    final String bucketName = widget.vehicle.brand.toLowerCase();
    
    for (int index = 0; index < widget.vehicle.detailPicCount; index++) {
      final String picName = "p${(index + 1).toString().padLeft(2, '0')}.jpg";
      
      // 💡 修正相對路徑：因為 Bucket 已經是品牌名了，路徑裡不需要再包含品牌名
      // 依據 Python 規則：posts/{shortcode}/images/detail/p01.jpg
      final String relativePath = "posts/${widget.vehicle.postId}/images/detail/$picName";
      
      try {
        final String signedUrl = await supabase.storage
            .from(bucketName)
            .createSignedUrl(relativePath, 3600);
        urls.add(signedUrl);
      } catch (e) {
        print('❌ 詳細細圖簽名失敗 (Bucket: $bucketName, Path: $relativePath): $e');
      }
    }
    
    if (urls.isEmpty && widget.vehicle.coverPath.isNotEmpty) {
      urls.add(widget.vehicle.coverPath);
    }
    return urls;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _entryController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    // 🔥 核心修正：檢查 soundFilePath 網址是否存在並改用 UrlSource
    if (widget.vehicle.hasPostSound && widget.vehicle.soundFilePath != null) {
      if (_isPlaying) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _isPlaying = false);
        await AudioManager.instance.resumeBgmAfterEngineSound();
      } else {
        await AudioManager.instance.pauseBgmForEngineSound();
        if (mounted) setState(() => _isPlaying = true);
        try {
          // 使用 UrlSource 播放來自 Supabase Storage 的雲端網路音檔
          await _audioPlayer.play(UrlSource(widget.vehicle.soundFilePath!));
        } catch (e) {
          if (mounted) setState(() => _isPlaying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('音訊播放失敗: $e')),
          );
        }
      }
    }
  }

  @override
Widget build(BuildContext context) {
  // 修正細圖拼接規則：
  // 檢查你的 Python 腳本，你的 Storage 路徑長這樣：
  // f"{brand}/{model}/post_{shortcode}/images/detail/p{detail_count:02d}.jpg"
  // 所以我們只需要把 Base URL 加上這個規則即可
  final String bucketBaseUrl = "https://fsqrgqpthqtvxfpxxxod.supabase.co/storage/v1/object/public/car-assets";
  
  final List<String> detailImages = List.generate(
    widget.vehicle.detailPicCount,
    (index) {
      // 這裡要用三位數 padLeft(2, '0') 配合你 Python 產生的 p01.jpg, p02.jpg
      final String picName = "p${(index + 1).toString().padLeft(2, '0')}.jpg";
      return "$bucketBaseUrl/${widget.vehicle.brand}/${widget.vehicle.model}/post_${widget.vehicle.postId}/images/detail/$picName";
    },
  );

  if (detailImages.isEmpty && widget.vehicle.coverPath.isNotEmpty) {
    detailImages.add(widget.vehicle.coverPath);
  }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFEAEAEA), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? const Color(0xFFD4AF37) : const Color(0xFFEAEAEA)),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              widget.onToggleFavorite();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頂部多圖大區塊 PageView
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  height: MediaQuery.of(context).size.height * (0.55 * _detailAspectRatio),
                  child: FutureBuilder<List<String>>(
                    future: _detailImagesFuture, // 📡 監聽細圖簽名狀態
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                      }
                      final detailImages = snapshot.data ?? [widget.vehicle.coverPath];

                      return PageView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: detailImages.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            detailImages[index], // 🔥 這是已經帶有安全過期 Token 的網址了！
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF161616),
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // 漸層遮罩
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black54, Colors.transparent, Colors.transparent, Color(0xFF0A0A0A)],
                          stops: [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // 寬度切換按鈕
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'toggle_aspect_ratio',
                    backgroundColor: Colors.black54,
                    child: Icon(
                      _isDetailImageWide ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: const Color(0xFFD4AF37),
                    ),
                    onPressed: () {
                      setState(() {
                        _isDetailImageWide = !_isDetailImageWide;
                      });
                    },
                  ),
                ),
                // 自訂指標圓點 Indicator
                if (detailImages.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        detailImages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          width: _currentImageIndex == index ? 16 : 4,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index ? const Color(0xFFD4AF37) : Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 下方資訊卡片區
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 品牌與車款名稱
                      Text(
                        widget.vehicle.brand.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.vehicle.model,
                        style: const TextStyle(color: Color(0xFFFAFAFA), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 18),

                      // 作者資訊欄位
                      Row(
                        children: [
                          // 🔥 核心修正：將大頭貼改為 Image.network 讀取雲端 URL
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF1A1A1A),
                            backgroundImage: widget.vehicle.authorAvatarPath.isNotEmpty
                                ? NetworkImage(widget.vehicle.authorAvatarPath)
                                : null,
                            child: widget.vehicle.authorAvatarPath.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '@${widget.vehicle.author}',
                            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          // 價格標籤
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF161410), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF332A15), width: 1)),
                            child: Text(
                              '${widget.vehicle.currency} ${(widget.vehicle.price / 10000).toStringAsFixed(0)}萬',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 引擎聲浪按鈕區塊
                      if (widget.vehicle.hasPostSound) ...[
                        GestureDetector(
                          onTap: _togglePlayback,
                          child: AnimatedBuilder(
                            animation: _shineController,
                            builder: (context, child) {
                              return Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: _isPlaying
                                        ? [const Color(0xFFC29B23), const Color(0xFFD4AF37), const Color(0xFFE5C14B)]
                                        : [const Color(0xFF161616), const Color(0xFF1F1F1F), const Color(0xFF161616)],
                                    transform: GradientRotation(_shineController.value * 2 * 3.1415),
                                  ),
                                  boxShadow: _isPlaying
                                      ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
                                      color: _isPlaying ? Colors.black : const Color(0xFFD4AF37),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isPlaying ? 'STOP ENGINE SOUND' : 'START ENGINE SOUND',
                                      style: TextStyle(
                                        color: _isPlaying ? Colors.black : const Color(0xFFE0E0E0),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 車輛性能數據規格
                      const Text(
                        'SPECIFICATIONS',
                        style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSpecTile('ENGINE', widget.vehicle.spec.engine, Icons.settings_input_component)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSpecTile('HORSEPOWER', '${widget.vehicle.spec.horsepower} HP', Icons.speed)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSpecTile('ORIGIN', widget.vehicle.spec.country, Icons.public)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSpecTile('TYPE', widget.vehicle.spec.vehicleType, Icons.directions_car)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // 評分與內文敘述
                      const Text(
                        'REVIEW & RATING',
                        style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _buildRatingRow(widget.vehicle.rating.ratingTitle1, widget.vehicle.rating.rating1),
                      const SizedBox(height: 12),
                      _buildRatingRow(widget.vehicle.rating.ratingTitle2, widget.vehicle.rating.rating2),
                      const SizedBox(height: 12),
                      _buildRatingRow(widget.vehicle.rating.ratingTitle3, widget.vehicle.rating.rating3),
                      const SizedBox(height: 24),
                      Text(
                        widget.vehicle.description,
                        style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15, height: 1.6, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A1A1A), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD4AF37).withOpacity(0.6), size: 16),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Color(0xFF555555), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String title, int score) {
    final normalizedScore = score.clamp(1, 5);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFFF2DF9A), fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: List.generate(
              5,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 5),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: index < normalizedScore ? const Color(0xFFC9A227) : const Color(0xFF262626),
                      border: Border.all(
                        color: index < normalizedScore ? const Color(0xFFF2DF9A) : const Color(0xFF3A3A3A),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$normalizedScore/5',
          style: const TextStyle(color: Color(0xFFD7B354), fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

extension on Scaffold {
  get appBorderRadius => null;
}