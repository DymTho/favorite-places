import 'package:favorite/providers/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Remembers whether it was closed.
class _TrackingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError('no network in tests');

  @override
  void close() => closed = true;
}

void main() {
  test('a map leaving the screen does not close the shared tile client', () async {
    final client = _TrackingClient();
    final container = ProviderContainer(
      overrides: [tileHttpClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);

    // A TileLayer does exactly this when its map is removed from the screen.
    container.read(tileProviderProvider).dispose();
    await Future<void>.delayed(Duration.zero);

    // If the client were closed here, every map shown afterwards would stay
    // empty (this was a real bug).
    expect(client.closed, isFalse);
  });
}
