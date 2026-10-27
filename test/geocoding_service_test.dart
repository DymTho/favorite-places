import 'dart:convert';

import 'package:favorite/data/geocoding_service.dart';
import 'package:favorite/models/place.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

GeocodingService _service(MockClientHandler handler, {String key = 'test-key'}) =>
    GeocodingService(client: MockClient(handler), apiKey: key);

http.Response _json(Map<String, Object?> body, [int status = 200]) =>
    http.Response(json.encode(body), status);

void main() {
  group('formatCoordinates', () {
    test('uses N/E for positive and S/W for negative values', () {
      expect(formatCoordinates(62.4722, 6.1549), '62.4722° N, 6.1549° E');
      expect(formatCoordinates(-33.8688, -151.2093), '33.8688° S, 151.2093° W');
    });
  });

  group('reverseGeocode', () {
    test('returns the formatted address when Google answers OK', () async {
      late Uri seen;
      final service = _service((request) async {
        seen = request.url;
        return _json({
          'results': [
            {'formattedAddress': 'Korsegata 9, 6002 Ålesund, Norway'},
            {'formattedAddress': 'Korsegata 8, 6002 Ålesund, Norway'},
          ],
        });
      });

      final address = await service.reverseGeocode(62.4722, 6.1549);

      // The first (most specific) result is used.
      expect(address, 'Korsegata 9, 6002 Ålesund, Norway');
      expect(seen.host, 'geocode.googleapis.com');
      expect(seen.path, '/v4/geocode/location/62.4722,6.1549');
      expect(seen.queryParameters['key'], 'test-key');
    });

    test('prefers a readable address over a plus code', () async {
      final service = _service(
        (_) async => _json({
          'results': [
            {
              'formattedAddress': 'FJ54+8C, Innfjorden, Norway',
              'types': ['plus_code'],
            },
            {
              'formattedAddress': 'Innfjorden, Norway',
              'types': ['locality', 'political'],
            },
          ],
        }),
      );
      expect(await service.reverseGeocode(62.4583, 7.6061), 'Innfjorden, Norway');
    });

    test('uses the plus code when it is all there is', () async {
      final service = _service(
        (_) async => _json({
          'results': [
            {
              'formattedAddress': 'FJ54+8C, Innfjorden, Norway',
              'types': ['plus_code'],
            },
          ],
        }),
      );
      expect(
        await service.reverseGeocode(62.4583, 7.6061),
        'FJ54+8C, Innfjorden, Norway',
      );
    });

    test('falls back to the coordinates when nothing was found', () async {
      // For the sea, Google answers an object without "results".
      expect(
        await _service((_) async => _json({})).reverseGeocode(0, 0),
        '0.0000° N, 0.0000° E',
      );
      expect(
        await _service((_) async => _json({'results': []})).reverseGeocode(0, 0),
        '0.0000° N, 0.0000° E',
      );
    });

    test('falls back when the key is rejected', () async {
      final service = _service(
        (_) async => _json({
          'error': {'code': 403, 'status': 'PERMISSION_DENIED'},
        }, 403),
      );
      expect(await service.reverseGeocode(62.4722, 6.1549), '62.4722° N, 6.1549° E');
    });

    test('falls back on an HTTP error, bad JSON or no internet', () async {
      expect(
        await _service((_) async => http.Response('oops', 500)).reverseGeocode(1, 1),
        '1.0000° N, 1.0000° E',
      );
      expect(
        await _service((_) async => http.Response('<html>', 200)).reverseGeocode(1, 1),
        '1.0000° N, 1.0000° E',
      );
      expect(
        await _service((_) async => throw Exception('offline')).reverseGeocode(1, 1),
        '1.0000° N, 1.0000° E',
      );
    });

    test('does not call the network without a real key', () async {
      var calls = 0;
      final service = _service((_) async {
        calls++;
        return http.Response('', 200);
      }, key: '');
      expect(service.hasKey, isFalse);
      expect(await service.reverseGeocode(62.4722, 6.1549), '62.4722° N, 6.1549° E');
      expect(calls, 0);
    });
  });
}
