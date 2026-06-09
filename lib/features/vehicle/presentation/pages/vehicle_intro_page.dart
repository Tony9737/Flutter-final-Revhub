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
      duration: const Duration(milliseconds: 900),
    );
    
    // _shineController 同時驅動卡片流光與音效按鈕的漸層旋轉
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
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

  Future<List<String>> _getSignedDetailImages() async {
    final supabase = Supabase.instance.client;
    final List<String> urls = [];
    final String bucketName = widget.vehicle.brand.toLowerCase();
    
    for (int index = 0; index < widget.vehicle.detailPicCount; index++) {
      final String picName = "p${(index + 1).toString().padLeft(2, '0')}.jpg";
      final String relativePath = "posts/${widget.vehicle.postId}/images/detail/$picName";
      
      try {
        final String signedUrl = await supabase.storage
            .from(bucketName)
            .createSignedUrl(relativePath, 3600);
        
        urls.add(signedUrl);

        if (mounted) {
          precacheImage(NetworkImage(signedUrl), context);
        }
      } catch (e) {
        debugPrint('⚠ 略過不存在的圖片 (Path: $relativePath): $e');
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
    if (widget.vehicle.hasPostSound && widget.vehicle.soundFilePath != null) {
      if (_isPlaying) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _isPlaying = false);
        await AudioManager.instance.resumeBgmAfterEngineSound();
      } else {
        await AudioManager.instance.pauseBgmForEngineSound();
        if (mounted) setState(() => _isPlaying = true);
        try {
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
    final String officialImageUrl = 
        "https://fsqrgqpthqtvxfpxxxod.supabase.co/storage/v1/object/public/car-assets/${widget.vehicle.brand}/${widget.vehicle.model}/official/cover.jpg";

    // 2. 最外層包覆展間背景圖片 Container
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background/showroom_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 讓外層背景透進來
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent, // AppBar 透明留白
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFF2DF9A), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Car Appreciation',
            style: TextStyle(color: Color(0xFFF2DF9A), fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: const Color(0xFFD7B354)),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
                widget.onToggleFavorite();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isFavorite ? '已加入收藏' : '已取消收藏')),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        // 1. 移除 extendBodyBehindAppBar: true，讓內容從 AppBar 下方開始，達成留白效果
        extendBodyBehindAppBar: false, 
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頂部多圖大區塊
              FutureBuilder<List<String>>(
                future: _detailImagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.45,
                      color: Colors.black87,
                      child: const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
                    );
                  }

                  final images = snapshot.data ?? [widget.vehicle.coverPath];

                  return Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        height: MediaQuery.of(context).size.height * (0.55 * _detailAspectRatio),
                        child: PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF161616),
                                child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                              ),
                            );
                          },
                        ),
                      ),
                      // 漸層遮罩（調整下方顏色，使其更自然融入背景）
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                                stops: const [0.0, 0.2, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 國家標籤（因應排版上移，將原本的 kToolbarHeight 拔除，修正為相對頂部 16）
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x99110E06),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0x99D7B354)),
                          ),
                          child: Text(
                            '${widget.vehicle.spec.country} Collection',
                            style: const TextStyle(color: Color(0xFFF4DF96), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      // 寬度切換按鈕
                      Positioned(
                        right: 16,
                        bottom: 24,
                        child: FloatingActionButton.small(
                          heroTag: 'toggle_aspect_ratio',
                          backgroundColor: const Color(0xB3161209),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xBFD7B354), width: 1.1)
                          ),
                          child: Icon(
                            _isDetailImageWide ? Icons.zoom_in_map : Icons.zoom_out_map,
                            color: const Color(0xFFD4AF37),
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() => _isDetailImageWide = !_isDetailImageWide);
                          },
                        ),
                      ),
                      // 指標圓點 Indicator
                      if (images.length > 1)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 28,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: _currentImageIndex == index ? 18 : 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index ? const Color(0xFFD4AF37) : Colors.white24,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              // 下方作者與卡片區
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // 作者資訊欄位
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xCC121212), // 微透明融入背景
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x66C9A227)),
                          ),
                          child: Row(
                            children: [
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
                                style: const TextStyle(color: Color(0xFFF6E7B5), fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.share, color: Color(0xFFD7B354), size: 20),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(text: "https://revhub.example.com")); 
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已複製來源連結')),
                                  );
                                },
                              ),
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
                        ),
                        const SizedBox(height: 16),

                        // 經典紳士資訊卡片
                        _buildGentlemanInfoCard(officialImageUrl),
                        const SizedBox(height: 20),

                        // 3. 旋轉流光引擎聲浪按鈕區塊
                        if (widget.vehicle.hasPostSound) ...[
                          AnimatedBuilder(
                            animation: _shineController,
                            builder: (context, child) {
                              return GestureDetector(
                                onTap: _togglePlayback,
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      colors: _isPlaying
                                          ? [const Color(0xFFC29B23), const Color(0xFFD4AF37), const Color(0xFFE5C14B)]
                                          : [const Color(0xFF161616), const Color(0xFF1F1F1F), const Color(0xFF161616)],
                                      transform: GradientRotation(_shineController.value * 2 * 3.14159),
                                    ),
                                    boxShadow: _isPlaying
                                        ? [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]
                                        : null,
                                    border: Border.all(
                                      color: _isPlaying ? const Color(0xFFF2DF9A) : const Color(0x33C9A227),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isPlaying ? Icons.stop_circle_rounded : Icons.sports_motorsports,
                                        // 當播放中背景變亮金時，圖示轉為深色以提升對比度
                                        color: _isPlaying ? const Color(0xFF110E06) : const Color(0xFFF2DF9A),
                                        size: 26,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isPlaying ? 'STOP ENGINE SOUND' : 'START ENGINE SOUND',
                                        style: TextStyle(
                                          color: _isPlaying ? const Color(0xFF110E06) : Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 高質感流光紳士資訊卡片
  Widget _buildGentlemanInfoCard(String officialImageUrl) {
    return Card(
      elevation: 14,
      color: Colors.transparent,
      shadowColor: const Color(0x77000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFC9A227), width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xEE151515), Color(0xEE0D0D0D), Color(0xEE20180C)], // 略帶透明度透出展間背景
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 左側：原廠車的圖片
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 125,
                            height: 110,
                            color: const Color(0xFF15120D),
                            child: Image.network(
                              officialImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF2D2D2D),
                                alignment: Alignment.center,
                                child: const Icon(Icons.directions_car, color: Color(0xFFD7B354), size: 34),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // 右側：車款名稱與主要規格
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.vehicle.brand.toUpperCase()} ${widget.vehicle.model}',
                                style: const TextStyle(
                                  color: Color(0xFFF7E6A8),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _specLine(Icons.settings_input_component, widget.vehicle.spec.engine),
                              const SizedBox(height: 5),
                              _specLine(Icons.speed, '${widget.vehicle.spec.horsepower} HP'),
                              const SizedBox(height: 5),
                              _specLine(Icons.directions_car, widget.vehicle.spec.vehicleType),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 分隔線
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x00C9A227), Color(0xAAC9A227), Color(0x00C9A227)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 車輛介紹
                    const Text(
                      '車輛介紹',
                      style: TextStyle(color: Color(0xFFE8C86C), fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.vehicle.description,
                      style: const TextStyle(color: Color(0xFFF4E6BE), fontSize: 14, height: 1.6, letterSpacing: 0.15),
                    ),
                    const SizedBox(height: 16),
                    // 主觀評分
                    const Text(
                      '主觀評分',
                      style: TextStyle(color: Color(0xFFE8C86C), fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 12),
                    _ratingRow(widget.vehicle.rating.ratingTitle1, widget.vehicle.rating.rating1),
                    const SizedBox(height: 8),
                    _ratingRow(widget.vehicle.rating.ratingTitle2, widget.vehicle.rating.rating2),
                    const SizedBox(height: 8),
                    _ratingRow(widget.vehicle.rating.ratingTitle3, widget.vehicle.rating.rating3),
                  ],
                ),
              ),
            ),
            
            // 卡片本身的流光動畫層
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    final sweep = (_shineController.value * 2.4) - 1.2;
                    return Transform.translate(
                      offset: Offset(MediaQuery.sizeOf(context).width * sweep, 0),
                      child: OverflowBox(
                        maxHeight: 1000,
                        child: Transform.rotate(angle: -0.45, child: child),
                      ),
                    );
                  },
                  child: Align(
                    alignment: const Alignment(0.0, 0.0),
                    child: Container(
                      width: 90,
                      height: 1000,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0x00F4DF96),
                            const Color(0x66F4DF96).withValues(alpha: 0.25),
                            const Color(0x00F4DF96),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFC7A74C)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFD8D1BF), fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _ratingRow(String title, int score) {
    final normalizedScore = score.clamp(1, 5);
    return Row(
      children: [
        SizedBox(
          width: 64,
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
                    height: 9,
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