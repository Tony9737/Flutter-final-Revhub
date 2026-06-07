// features/vehicle/domain/entities/vehicle.dart

class Vehicle {
  // 車款基本資料 (來自 vehicles 表)
  final String carID;
  final String brand;
  final String model;
  final String currency;
  final int price;
  final bool hasSound;
  final String? soundPath;
  final VehicleSpec spec;

  // 貼文資訊 (來自 posts 表)
  final String postId;
  final String author;
  final String authorAvatarPath;
  final String coverPath;
  final String sourceUrl;
  final String description;
  final int detailPicCount;
  final bool isVideo;
  final bool hasPostSound;
  final bool isGifCover;
  final String? soundFilePath;
  final VehicleRating rating;

  const Vehicle({
    required this.carID,
    required this.brand,
    required this.model,
    required this.currency,
    required this.price,
    required this.hasSound,
    this.soundPath,
    required this.spec,
    required this.postId,
    required this.author,
    required this.authorAvatarPath,
    required this.coverPath,
    required this.sourceUrl,
    required this.description,
    required this.detailPicCount,
    required this.isVideo,
    required this.hasPostSound,
    required this.isGifCover,
    this.soundFilePath,
    required this.rating,
  });
}

class VehicleSpec {
  final String engine;
  final int horsepower;
  final String country;
  final String vehicleType;
  final String? officialImage;

  const VehicleSpec({
    required this.engine,
    required this.horsepower,
    required this.country,
    required this.vehicleType,
    this.officialImage,
  });
}

class VehicleRating {
  final String ratingTitle1;
  final String ratingTitle2;
  final String ratingTitle3;
  final int rating1;
  final int rating2;
  final int rating3;

  const VehicleRating({
    required this.ratingTitle1,
    this.ratingTitle2 = '速度',
    this.ratingTitle3 = '實用度',
    required this.rating1,
    required this.rating2,
    required this.rating3,
  });
}