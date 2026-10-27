import 'package:location/location.dart';

/// A GPS position without an address.
typedef Coordinates = ({double latitude, double longitude});

/// Shown to the user as it is, so the messages are written for people.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads the phone's current position.
abstract class LocationService {
  Future<Coordinates> getCurrentLocation();
}

/// Uses the `location` plugin. The three steps the plugin docs ask for:
/// 1. is the location service (GPS switch) on?  2. do we have permission?
/// 3. read the position.
class DeviceLocationService implements LocationService {
  DeviceLocationService([Location? location]) : _location = location ?? Location();

  final Location _location;

  @override
  Future<Coordinates> getCurrentLocation() async {
    try {
      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        // Android shows the system dialog "Turn on location?".
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw const LocationException(
            'Location is switched off. Turn it on to use your current position.',
          );
        }
      }

      var permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        // The system permission dialog appears here.
        permission = await _location.requestPermission();
      }
      if (permission == PermissionStatus.deniedForever) {
        throw const LocationException(
          'Location permission is blocked. Allow it in the phone settings.',
        );
      }
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        throw const LocationException(
          'Location permission was denied. You can still pick a place on the map.',
        );
      }

      final data = await _location.getLocation().timeout(
            const Duration(seconds: 20),
          );
      return (latitude: data.latitude, longitude: data.longitude);
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(
        'Could not get your position. Check that location is on and try again.',
      );
    }
  }
}
