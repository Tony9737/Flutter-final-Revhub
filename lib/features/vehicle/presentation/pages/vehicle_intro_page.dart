import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_final_revhub/services/audio/audio_manager.dart';
import '../../domain/entities/vehicle.dart';

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
  int _currentImageIndex = 0; // 用於圖片底下的圓點指示
  late final AnimationController _entryController;
  late final AnimationController _shineController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  double get _detailAspectRatio => _isDetailImageWide ? 3 / 4 : 1;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _audioPlayer.onPlayerComplete.listen((_) async {
      if (!mounted || !_isPlaying) return;
      setState(() => _isPlaying = false);
      await AudioManager.instance.resumeBgmAfterEngineSound();
    });

    _entryController.forward();
  }

  // 按下按鈕：播放音效
  void _playEngineSound() async {
    if (widget.vehicle.media.hasSound &&
        widget.vehicle.media.soundFilePath != null) {
      await AudioManager.instance.pauseBgmForEngineSound();
      setState(() => _isPlaying = true);
      await _audioPlayer.play(
        AssetSource(
          widget.vehicle.media.soundFilePath!.replaceFirst('assets/', ''),
        ),
      );
    }
  }

  // 鬆開按鈕：停止音效
  void _stopEngineSound() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
      await AudioManager.instance.resumeBgmAfterEngineSound();
    }
  }

  @override
  void dispose() {
    if (_isPlaying) {
      AudioManager.instance.resumeBgmAfterEngineSound();
    }
    _entryController.dispose();
    _shineController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/background/showroom_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFF2DF9A)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Car Appreciation',
            style: const TextStyle(
              color: Color(0xFFF2DF9A),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x66C9A227)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: Image.asset(
                          '${widget.vehicle.media.coverPath}/images/cover/author.jpg',
                        ).image,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.vehicle.author,
                          style: const TextStyle(
                            color: Color(0xFFF6E7B5),
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '複製來源連結',
                        icon: const Icon(
                          Icons.content_paste,
                          color: Color(0xFFD7B354),
                          size: 22,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.vehicle.media.sourceUrl),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已複製來源連結')),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: _isFavorite ? '取消收藏' : '加入收藏',
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          color: const Color(0xFFD7B354),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          widget.onToggleFavorite();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isFavorite ? '已加入收藏' : '已取消收藏'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: AspectRatio(
                          aspectRatio: _detailAspectRatio,
                          child: PageView.builder(
                            clipBehavior: Clip.hardEdge,
                            itemCount: widget.vehicle.media.detailPicCount,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imagePath =
                                  '${widget.vehicle.media.coverPath}/images/detail/p${index + 1}.jpg';
                              return Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey[900],
                                      alignment: Alignment.center,
                                      child: Text(
                                        '找不到圖片:\n$imagePath',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x99110E06),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0x99D7B354)),
                          ),
                          child: Text(
                            '${widget.vehicle.spec.country} Collection',
                            style: const TextStyle(
                              color: Color(0xFFF4DF96),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (widget.vehicle.media.detailPicCount > 1)
                        Positioned(
                          bottom: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.vehicle.media.detailPicCount,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _currentImageIndex == index ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _currentImageIndex == index
                                      ? const Color(0xFFD7B354)
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 12,
                        bottom: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              setState(() {
                                _isDetailImageWide = !_isDetailImageWide;
                              });
                            },
                            child: Ink(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xB3161209),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xBFD7B354),
                                  width: 1.1,
                                ),
                              ),
                              child: Icon(
                                _isDetailImageWide
                                    ? Icons.zoom_in_map
                                    : Icons.zoom_out_map,
                                size: 18,
                                color: const Color(0xFFF2DF9A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildGentlemanInfoCard(),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // 按住播放引擎音浪按鈕 (若有設定檔案才顯示)
              if (widget.vehicle.media.hasSound &&
                  (widget.vehicle.media.soundFilePath?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: GestureDetector(
                    onTapDown: (_) => _playEngineSound(), // 按下
                    onTapUp: (_) => _stopEngineSound(), // 鬆開
                    onTapCancel: () => _stopEngineSound(), // 移開或被中斷
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        // 按下時變成紅色，平時是深灰色
                        color: _isPlaying
                            ? const Color(0xFF191919)
                            : const Color(0xFF191919),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isPlaying
                              ? const Color(0xFFD7B354)
                              : const Color(0x55C9A227),
                          width: 2,
                        ),
                        boxShadow: _isPlaying
                            ? [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying
                                ? Icons.volume_up
                                : Icons.sports_motorsports,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isPlaying ? 'Enjoy :)' : '按住聆聽引擎音浪',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 底部留白
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGentlemanInfoCard() {
    return Card(
      elevation: 14,
      color: Colors.transparent,
      shadowColor: const Color(0x55000000),
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
                  colors: [
                    Color(0xFF151515),
                    Color(0xFF0D0D0D),
                    Color(0xFF20180C),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 125,
                            height: 110,
                            color: const Color(0xFF15120D),
                            alignment: Alignment.center,
                            child: Image.asset(
                              '${widget.vehicle.media.coverPath}/images/cover/stock.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFF2D2D2D),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFFD7B354),
                                      size: 34,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.vehicle.brand} ${widget.vehicle.model}',
                                style: const TextStyle(
                                  color: Color(0xFFF7E6A8),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _specLine(
                                Icons.settings,
                                widget.vehicle.spec.engine,
                              ),
                              const SizedBox(height: 5),
                              _specLine(
                                Icons.speed,
                                '${widget.vehicle.spec.horsepower} hp',
                              ),
                              const SizedBox(height: 5),
                              _specLine(
                                Icons.public,
                                widget.vehicle.spec.country,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00C9A227),
                            Color(0xAAC9A227),
                            Color(0x00C9A227),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '車輛介紹',
                      style: TextStyle(
                        color: Color(0xFFE8C86C),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.vehicle.description,
                      style: const TextStyle(
                        color: Color(0xFFF4E6BE),
                        fontSize: 14.5,
                        height: 1.65,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '主觀評分',
                      style: TextStyle(
                        color: Color(0xFFE8C86C),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ratingRow(
                      widget.vehicle.rating.ratingTitle1,
                      widget.vehicle.rating.rating1,
                    ),
                    const SizedBox(height: 8),
                    _ratingRow(
                      widget.vehicle.rating.ratingTitle2,
                      widget.vehicle.rating.rating2,
                    ),
                    const SizedBox(height: 8),
                    _ratingRow(
                      widget.vehicle.rating.ratingTitle3,
                      widget.vehicle.rating.rating3,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    final sweep = (_shineController.value * 2.4) - 1.2;
                    return Transform.translate(
                      offset: Offset(
                        MediaQuery.sizeOf(context).width * sweep,
                        0,
                      ),
                      child: OverflowBox(
                        maxHeight: 1000,
                        child: Transform.rotate(angle: -0.45, child: child),
                      ),
                    );
                  },
                  child: Align(
                    alignment: const Alignment(0.0, 0.0),
                    child: Container(
                      width: 88,
                      height: 1000,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0x00F4DF96),
                            const Color(0x66F4DF96).withValues(alpha: 0.28),
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
        Icon(icon, size: 16, color: const Color(0xFFC7A74C)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD8D1BF),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _ratingRow(String title, int score) {
    final normalizedScore = score.clamp(0, 5);

    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF2DF9A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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
                      color: index < normalizedScore
                          ? const Color(0xFFC9A227)
                          : const Color(0xFF262626),
                      border: Border.all(
                        color: index < normalizedScore
                            ? const Color(0xFFF2DF9A)
                            : const Color(0xFF3A3A3A),
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
          style: const TextStyle(
            color: Color(0xFFD7B354),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
