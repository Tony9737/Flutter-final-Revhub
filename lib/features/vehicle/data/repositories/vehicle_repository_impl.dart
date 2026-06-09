// features/vehicle/data/repositories/vehicle_repository_impl.dart

import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasource/vehicle_remote_datasource.dart';
import '../models/vehicle_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  static const Duration _cacheDuration = Duration(minutes: 10);
  static List<Vehicle>? _cachedVehicles;
  static DateTime? _lastFetchedAt;
  static Future<List<Vehicle>>? _inFlightRequest;

  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Vehicle>> getVehiclePosts({bool forceRefresh = false}) async {
    final shouldUseCache = !forceRefresh &&
        _cachedVehicles != null &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < _cacheDuration;

    if (shouldUseCache) {
      return _cachedVehicles!;
    }

    if (!forceRefresh && _inFlightRequest != null) {
      return _inFlightRequest!;
    }

    final request = _fetchAndCacheVehicles();
    _inFlightRequest = request;

    try {
      return await request;
    } finally {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
      }
    }
  }

  Future<List<Vehicle>> _fetchAndCacheVehicles() async {
    try {
      final rawData = await remoteDataSource.fetchVehiclePostsWithSpecs();

      final List<Vehicle> vehicles = await Future.wait(
        rawData.map((json) => VehicleModel.fromMapAsync(json)),
      );

      _cachedVehicles = vehicles;
      _lastFetchedAt = DateTime.now();

      return vehicles;
    } catch (e) {
      throw Exception('Repository 層解析與私有網址簽名失敗: $e');
    }
  }
}