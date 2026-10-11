import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Computes the great-circle distance between two lat/lng points using the
/// Haversine formula. Returns the distance in kilometers.
double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (pi / 180.0);

/// Result of attempting to read the device's current location.
class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  const LocationResult({this.latitude, this.longitude, this.error});

  bool get isSuccess => error == null && latitude != null && longitude != null;
}

/// Requests location permission (if needed) and returns the device's current
/// GPS position. Never throws — failures are surfaced via [LocationResult.error]
/// so callers can show a friendly message and fall back to manual entry.
Future<LocationResult> getCurrentDeviceLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(error: 'Location services are turned off on this device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(error: 'Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
          error: 'Location permission is permanently denied. Enable it from device settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult(latitude: position.latitude, longitude: position.longitude);
  } catch (e) {
    return LocationResult(error: 'Could not get location: $e');
  }
}

/// Formats a distance in km for display, e.g. "2.4 km away" or "850 m away".
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m away';
  return '${km.toStringAsFixed(1)} km away';
}
