// features/vehicle/data/repositories/vehicle_repository_impl.dart

import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasource/vehicle_remote_datasource.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Vehicle>> getVehiclePosts() async {
    try {
      // 1. 撈取 Supabase 原始 Join 的資料
      final rawData = await remoteDataSource.fetchVehiclePostsWithSpecs();
      
      // 2. 🔥 修正：使用 Future.wait 非同步並行處理每一筆車輛的私有雲端網址簽名
      final List<Vehicle> vehicles = await Future.wait(
        rawData.map((json) => VehicleModel.fromMapAsync(json)),
      );
      
      return vehicles;
    } catch (e) {
      throw Exception('Repository 層解析與私有網址簽名失敗: $e');
    }
  }
}