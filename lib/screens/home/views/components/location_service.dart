import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // دالة لحفظ الإحداثيات
  Future<void> saveLocation(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', latitude);
    await prefs.setDouble('longitude', longitude);
  }

  // دالة لحساب المسافة بين نقطتين
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // نصف قطر الأرض بالكيلومترات
  print(lat1);
  print(lon1);
    // تحويل الدرجات إلى راديان
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
               sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // المسافة بالكيلومترات
  }

  // دالة لتحويل الدرجات إلى راديان
  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // دالة لجلب الإحداثيات من SharedPreferences
  Future<Map<String, double?>> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? latitude = prefs.getDouble('latitude');
    double? longitude = prefs.getDouble('longitude');
    return {'latitude': latitude, 'longitude': longitude};
  }
}