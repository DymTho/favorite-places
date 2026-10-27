import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../models/place.dart';

/// Turns coordinates into a street address with the Google **Geocoding API**
/// (v4, "reverse geocoding by location"), called over plain HTTP.
///
/// v4 is used because it also works with the free *Maps Demo Key* (no billing
/// account). The map itself is OpenStreetMap and needs no key at all.
class GeocodingService {
  GeocodingService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? ApiKeys.googleMapsApiKey;

  final http.Client _client;
  final String _apiKey;

  bool get hasKey => _apiKey.isNotEmpty && _apiKey != ApiKeys.placeholder;

  /// Asks Google for the address of a point. It never throws: when there is no
  /// key, no internet, or no answer, the readable coordinates are used instead,
  /// so a place can always be saved.
  Future<String> reverseGeocode(double latitude, double longitude) async {
    final fallback = formatCoordinates(latitude, longitude);
    if (!hasKey) return fallback;
    try {
      final uri = Uri.https(
        'geocode.googleapis.com',
        '/v4/geocode/location/$latitude,$longitude',
        {'key': _apiKey, 'languageCode': 'en'},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      // A wrong key, a key without this API or a quota problem is an HTTP error
      // status (403, 429, ...) with an error message in the body.
      if (response.statusCode != 200) return fallback;

      final body = json.decode(response.body) as Map<String, dynamic>;
      // `results` is missing or empty for places without an address (the sea).
      final results = body['results'];
      if (results is! List || results.isEmpty) return fallback;
      return _readableAddress(results) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  /// The results are ordered from the most specific one (a street address) to
  /// the least. Far from streets the first result is only a *plus code* like
  /// "FJ54+8C, Innfjorden", which is not readable for people, so the first
  /// result of another kind (a village, a municipality...) is preferred.
  String? _readableAddress(List<dynamic> results) {
    String? firstPlusCode;
    for (final result in results) {
      if (result is! Map<String, dynamic>) continue;
      final address = result['formattedAddress'];
      if (address is! String || address.isEmpty) continue;
      final types = result['types'];
      final isPlusCode = types is List && types.contains('plus_code');
      if (!isPlusCode) return address;
      firstPlusCode ??= address;
    }
    return firstPlusCode;
  }
}
