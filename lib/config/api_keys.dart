/// The private Google API key, used for exactly one thing: turning coordinates
/// into a street address (Google Geocoding API v4). The map itself is
/// OpenStreetMap and needs no key at all.
///
/// IMPORTANT: never commit or hand in a real key. The assignment requires removing
/// private keys before submitting, so the delivered value must be the placeholder.
///
/// Two ways to give the app a key:
///  - paste it into [_yourKey] below (and put it back to [placeholder] afterwards), or
///  - run with `flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key`, which
///    leaves nothing in the code to remove.
/// Without a key the app still works: a place simply gets its coordinates as its
/// address (for example `62.4722° N, 6.1549° E`).
class ApiKeys {
  const ApiKeys._();

  /// The value that means "no key yet". Never put a real key here: the
  /// geocoding service compares against it.
  static const placeholder = 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Paste your key here while developing.
  /// REMOVE IT (set it back to [placeholder]) BEFORE SUBMITTING.
  static const _yourKey = placeholder;

  /// `String.fromEnvironment` reads a value given with `--dart-define` at build
  /// time; without one [_yourKey] is used.
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: _yourKey,
  );
}
