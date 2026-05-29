// 定義車輛資料結構，包含基本資訊、規格與多媒體資料
class Vehicle {
  final String brand;
  final String model;
  final String description;
  final String author;
  final String currency;
  final int price;

  final VehicleSpec spec;
  final VehicleMedia media;
  final VehicleRating rating;

  const Vehicle({
    required this.brand,
    required this.model,
    required this.description,
    required this.author,
    required this.currency,
    required this.price,
    required this.spec,
    required this.media,
    required this.rating,
  });
}

String vehicleFavoriteKey(Vehicle vehicle) =>
    '${vehicle.brand}::${vehicle.model}';

// 專門處理車輛規格
class VehicleSpec {
  final String engine;
  final int horsepower;
  final String country;
  final String vehicleType;

  const VehicleSpec({
    required this.engine,
    required this.horsepower,
    required this.country,
    required this.vehicleType,
  });
}

// 專門處理多媒體與路徑
class VehicleMedia {
  final String coverPath;
  final String sourceUrl;
  final int detailPicCount;
  final bool hasSound;
  final bool isGifCover;
  final String? soundFilePath;

  const VehicleMedia({
    required this.coverPath,
    required this.sourceUrl,
    required this.detailPicCount,
    this.hasSound = false, // 給予預設值
    this.isGifCover = false, // 給予預設值
    this.soundFilePath,
  });
}

// 專門處理車輛評分
class VehicleRating {
  final String ratingTitle1;
  final String ratingTitle2 = '速度';
  final String ratingTitle3 = '實用度';
  final int rating1;
  final int rating2;
  final int rating3;

  const VehicleRating({
    required this.ratingTitle1,
    required this.rating1,
    required this.rating2,
    required this.rating3,
  });
}
