import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  Map<String, String> _addressParts = {};
  bool _isLoading = false;
  String? _error;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  Map<String, String> get addressParts => _addressParts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLocation() async {
    // If we already have a position, don't fetch again unless forced (could implement force refresh later)
    if (_currentPosition != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error =
            'Location permissions are permanently denied, we cannot request permissions.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _addressParts = {
          'area': place.subLocality ?? place.thoroughfare ?? '',
          'pincode': place.postalCode ?? '',
          'city': place.locality ?? place.subAdministrativeArea ?? '',
          'state': place.administrativeArea ?? '',
          'street': place.street ?? '',
        };

        List<String> validParts = [
          _addressParts['area']!,
          _addressParts['city']!,
          _addressParts['state']!,
          _addressParts['pincode']!,
        ].where((s) => s.isNotEmpty).toList();

        _currentAddress = validParts.join(', ');
      } else {
        _currentAddress = "Address not found";
      }
    } catch (e) {
      _error = 'Error getting location: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to force refresh if needed
  Future<void> refreshLocation() async {
    _currentPosition = null;
    await fetchLocation();
  }
}
