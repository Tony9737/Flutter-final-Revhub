// features/vehicle/data/models/vehicle_model.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.carID,
    required super.brand,
    required super.model,
    required super.currency,
    required super.price,
    required super.hasSound,
    super.soundPath,
    required super.spec,
    required super.postId,
    required super.author,
    required super.authorAvatarPath,
    required super.coverPath,
    required super.sourceUrl,
    required super.description,
    required super.detailPicCount,
    required super.isVideo,
    required super.hasPostSound,
    required super.isGifCover,
    super.soundFilePath,
    required super.rating,
  });

  /// 🔐 核心改動：非同步解析與 Private Bucket 簽名方法
  /// 時效設定為 3600 秒 (1小時)，滿足 Flutter 快取機制需求
  static Future<VehicleModel> fromMapAsync(Map<String, dynamic> map) async {
    final supabase = Supabase.instance.client;
    const int expireSeconds = 3600; // 臨時網址 1 小時有效

    String rawAvatarPath = map['author_avatar_path'] ?? '';
    String rawCoverPath = map['cover_path'] ?? '';
    String rawSoundPath = map['sound_file_path'] ?? '';

    /// 🛠️ 核心解析工具：從完整 URL 提取出 [Bucket名稱, 相對路徑]
    Map<String, String>? parseStorageUrl(String url) {
      if (url.isEmpty) return null;
      try {
        // 匹配 /object/public/ 或 /object/sign/ 後面的結構
        final regExp = RegExp(r'/object/(?:public|sign)/([^/]+)/(.+)$');
        final match = regExp.firstMatch(url);
        
        if (match != null) {
          final bucket = match.group(1)!; // 抓出第一個資料夾，例如 'audi'、'nissan'
          final path = match.group(2)!.split('?').first; // 抓出後面的相對路徑，並剔除可能殘留的 token
          return {'bucket': bucket, 'path': path};
        }
      } catch (e) {
        // print('解析網址失敗: $e');
      }
      return null;
    }

    String signedAvatar = '';
    String signedCover = '';
    String? signedSound;

    // 1. 為大頭貼簽名
    final avatarInfo = parseStorageUrl(rawAvatarPath);
    if (avatarInfo != null) {
      try {
        signedAvatar = await supabase.storage
            .from(avatarInfo['bucket']!)
            .createSignedUrl(avatarInfo['path']!, expireSeconds);
      } catch (e) {
        // print('❌ 頭像簽名失敗 (Bucket: ${avatarInfo['bucket']}, Path: ${avatarInfo['path']}): $e');
        // 如果簽名因為 RLS 失敗，保留原樣防呆
        signedAvatar = rawAvatarPath; 
      }
    } else {
      signedAvatar = rawAvatarPath;
    }

    // 2. 為封面圖簽名
    final coverInfo = parseStorageUrl(rawCoverPath);
    if (coverInfo != null) {
      try {
        signedCover = await supabase.storage
            .from(coverInfo['bucket']!)
            .createSignedUrl(coverInfo['path']!, expireSeconds);
      } catch (e) {
        // print('❌ 封面簽名失敗 (Bucket: ${coverInfo['bucket']}, Path: ${coverInfo['path']}): $e');
        signedCover = rawCoverPath;
      }
    } else {
      signedCover = rawCoverPath;
    }

    // 3. 為引擎聲浪音檔簽名
    final soundInfo = parseStorageUrl(rawSoundPath);
    if (soundInfo != null && (map['has_sound'] ?? false)) {
      try {
        signedSound = await supabase.storage
            .from(soundInfo['bucket']!)
            .createSignedUrl(soundInfo['path']!, expireSeconds);
      } catch (e) {
        // print('❌ 音檔簽名失敗 (Bucket: ${soundInfo['bucket']}, Path: ${soundInfo['path']}): $e');
        signedSound = rawSoundPath;
      }
    } else {
      signedSound = rawSoundPath.isNotEmpty ? rawSoundPath : null;
    }

    // 3. 解析其餘外層貼文欄位
    final String postId = map['post_id'] ?? '';
    final String author = map['author'] ?? '匿名';
    final String sourceUrl = map['source_url'] ?? '';
    final String description = map['description'] ?? '';
    final int detailPicCount = map['detail_pic_count'] ?? 0;
    final bool isVideo = map['is_video'] ?? false;
    final bool hasPostSound = map['has_sound'] ?? false;
    final bool isGifCover = map['is_gif_cover'] ?? false;

    // 4. 解析巢狀的 rating
    final Map<String, dynamic> ratingMap = map['rating'] as Map<String, dynamic>? ?? {};
    final VehicleRatingModel rating = VehicleRatingModel.fromMap(ratingMap);

    // 5. 解析 Join 進來的 vehicles 資料表
    final Map<String, dynamic> vehicleMap = map['vehicles'] as Map<String, dynamic>? ?? {};
    final String carID = vehicleMap['id'] ?? '';
    final String brand = vehicleMap['brand'] ?? '未知品牌';
    final String model = vehicleMap['model'] ?? '未知型號';
    final String currency = vehicleMap['currency'] ?? 'TWD';
    final int price = vehicleMap['price'] ?? 0;
    final bool hasSound = vehicleMap['has_sound'] ?? false;
    final String? soundPath = vehicleMap['sound_path'];

    // 6. 解析 spec
    final Map<String, dynamic> specMap = vehicleMap['spec'] as Map<String, dynamic>? ?? {};
    final VehicleSpecModel spec = VehicleSpecModel.fromMap(specMap);

    return VehicleModel(
      carID: carID,
      brand: brand,
      model: model,
      currency: currency,
      price: price,
      hasSound: hasSound,
      soundPath: soundPath,
      spec: spec,
      postId: postId,
      author: author,
      // 🔥 這裡塞入帶有臨時權限 Token 的真實網址，UI 就能直接無痛讀取了！
      authorAvatarPath: signedAvatar,
      coverPath: signedCover,
      soundFilePath: signedSound,
      sourceUrl: sourceUrl,
      description: description,
      detailPicCount: detailPicCount,
      isVideo: isVideo,
      hasPostSound: hasPostSound,
      isGifCover: isGifCover,
      rating: rating,
    );
  }
}

class VehicleSpecModel extends VehicleSpec {
  const VehicleSpecModel({required super.engine, required super.horsepower, required super.country, required super.vehicleType, super.officialImage});
  factory VehicleSpecModel.fromMap(Map<String, dynamic> map) {
    return VehicleSpecModel(
      engine: map['engine'] ?? '未知引擎',
      horsepower: map['horsepower'] ?? 0,
      country: map['country'] ?? '未知國家',
      vehicleType: map['vehicleType'] ?? '跑車',
      officialImage: map['officialImage'],
    );
  }
}

class VehicleRatingModel extends VehicleRating {
  const VehicleRatingModel({required super.ratingTitle1, super.ratingTitle2, super.ratingTitle3, required super.rating1, required super.rating2, required super.rating3});
  factory VehicleRatingModel.fromMap(Map<String, dynamic> map) {
    return VehicleRatingModel(
      ratingTitle1: map['ratingTitle1'] ?? '外觀',
      ratingTitle2: map['ratingTitle2'] ?? '速度',
      ratingTitle3: map['ratingTitle3'] ?? '實用度',
      rating1: map['rating1'] ?? 5,
      rating2: map['rating2'] ?? 5,
      rating3: map['rating3'] ?? 5,
    );
  }
}