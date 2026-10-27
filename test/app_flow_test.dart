import 'package:favorite/screens/add_place.dart';
import 'package:favorite/screens/map.dart';
import 'package:favorite/screens/place_detail.dart';
import 'package:favorite/screens/places_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:favorite/providers/user_places.dart';

import 'helpers/fakes.dart';

void main() {
  group('home screen', () {
    testWidgets('shows a friendly message when there are no places', (tester) async {
      await pumpApp(tester, TestEnv(), const PlacesListScreen());

      expect(find.text('No places yet'), findsOneWidget);
      expect(find.text('Add place'), findsOneWidget);
    });

    testWidgets('lists the stored places with their addresses', (tester) async {
      final env = TestEnv(places: [
        makePlace('Fjord view', address: 'Fjord Road 1'),
        makePlace('Old harbour', address: 'Quay 5'),
      ]);
      await pumpApp(tester, env, const PlacesListScreen());

      expect(find.text('Fjord view'), findsOneWidget);
      expect(find.text('Fjord Road 1'), findsOneWidget);
      expect(find.text('Old harbour'), findsOneWidget);
      expect(find.text('2 places saved'), findsOneWidget);
    });

    testWidgets('shows an error with "Try again" when loading fails', (tester) async {
      final env = TestEnv(places: [makePlace('Fjord view')])
        ..repository.failReads = true;
      await pumpApp(tester, env, const PlacesListScreen());
      expect(find.text('Could not load your places.'), findsOneWidget);

      env.repository.failReads = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Fjord view'), findsOneWidget);
    });

    testWidgets('search filters the list and can be cleared', (tester) async {
      final env = TestEnv(places: [
        makePlace('Fjord view'),
        makePlace('Old harbour'),
      ]);
      await pumpApp(tester, env, const PlacesListScreen());

      await tester.enterText(find.byType(TextField), 'harb');
      await tester.pumpAndSettle();
      expect(find.text('Old harbour'), findsOneWidget);
      expect(find.text('Fjord view'), findsNothing);

      await tester.enterText(find.byType(TextField), 'nothing like this');
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Fjord view'), findsOneWidget);
      expect(find.text('Old harbour'), findsOneWidget);
    });

    testWidgets('the heart saves a favorite and the Favorites tab shows it', (tester) async {
      final env = TestEnv(places: [
        makePlace('Fjord view'),
        makePlace('Old harbour'),
      ]);
      await pumpApp(tester, env, const PlacesListScreen());

      await tester.tap(find.byTooltip('Add to favorites').first);
      await tester.pumpAndSettle();
      expect(env.repository.places.where((p) => p.isFavorite), hasLength(1));

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });

    testWidgets('the Favorites tab explains itself when empty', (tester) async {
      final env = TestEnv(places: [makePlace('Fjord view')]);
      await pumpApp(tester, env, const PlacesListScreen());

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets('the Map tab has a message when there are no places', (tester) async {
      await pumpApp(tester, TestEnv(), const PlacesListScreen());

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to show yet'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
    });

    testWidgets('the Map tab shows a pin for every place', (tester) async {
      final env = TestEnv(places: [
        makePlace('Fjord view'),
        makePlace('Old harbour'),
      ]);
      await pumpApp(tester, env, const PlacesListScreen());

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsNWidgets(2));
    });

    testWidgets('swiping a card removes the place, Undo brings it back', (tester) async {
      final env = TestEnv(places: [makePlace('Fjord view')]);
      await pumpApp(tester, env, const PlacesListScreen());

      await tester.drag(find.byType(Dismissible), const Offset(700, 0));
      await tester.pumpAndSettle();

      expect(find.text('Fjord view'), findsNothing); // the card is gone
      expect(find.text('"Fjord view" removed'), findsOneWidget);
      expect(env.repository.places, isEmpty);
      expect(env.imageStore.deleted, isEmpty); // the photo is kept for Undo

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Fjord view'), findsOneWidget);
      expect(env.repository.places, hasLength(1));
    });
  });

  group('add place form', () {
    Future<void> openForm(WidgetTester tester, TestEnv env) async {
      await pumpApp(tester, env, const PlacesListScreen());
      await tester.tap(find.text('Add place'));
      await tester.pumpAndSettle();
      expect(find.byType(AddPlaceScreen), findsOneWidget);
    }

    testWidgets('shows a message for every missing field and saves nothing', (tester) async {
      final env = TestEnv();
      await openForm(tester, env);

      await tester.tap(find.text('Add Place'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title.'), findsOneWidget);
      expect(find.text('Please take or choose a picture.'), findsOneWidget);
      expect(find.text('Please choose a location.'), findsOneWidget);
      expect(env.repository.places, isEmpty);
      expect(find.byType(AddPlaceScreen), findsOneWidget);
    });

    testWidgets('a one-letter title is rejected', (tester) async {
      await openForm(tester, TestEnv());

      await tester.enterText(find.byType(TextFormField), 'A');
      await tester.pumpAndSettle();

      expect(find.text('The title must have at least 2 characters.'), findsOneWidget);
    });

    testWidgets('a taken picture and a current location are shown in the form', (tester) async {
      final env = TestEnv();
      await openForm(tester, env);

      expect(find.text('No image taken'), findsOneWidget);
      expect(find.text('No location chosen'), findsOneWidget);

      await tester.tap(find.text('Take Picture'));
      await tester.pumpAndSettle();
      expect(env.photos.cameraCalls, 1);
      expect(find.text('No image taken'), findsNothing);
      // Touching one field must not flag the other, untouched fields.
      expect(find.text('Please enter a title.'), findsNothing);
      expect(find.text('Please choose a location.'), findsNothing);

      await tester.tap(find.text('Get Current Location'));
      await tester.pumpAndSettle();
      // Without an API key the address is the readable coordinates.
      expect(find.text('62.4722° N, 6.1549° E'), findsOneWidget);
      expect(find.text('No location chosen'), findsNothing);
    });

    testWidgets('"Select on Map" returns the tapped point to the form', (tester) async {
      final env = TestEnv();
      await openForm(tester, env);

      await tester.tap(find.text('Select on Map'));
      await tester.pumpAndSettle();
      expect(find.text('Pick your Location'), findsOneWidget);

      await tester.tap(find.byType(FlutterMap));
      // flutter_map waits a moment to tell a tap from a double tap.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();

      // Back in the form. The map opens centred on NTNU, and the tap hit its
      // centre. Without an API key the address is the readable coordinates.
      expect(find.byType(AddPlaceScreen), findsOneWidget);
      expect(find.text('No location chosen'), findsNothing);
      expect(find.text('62.4722° N, 6.1549° E'), findsOneWidget);
    });

    testWidgets('the gallery button picks a photo too', (tester) async {
      final env = TestEnv();
      await openForm(tester, env);

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      expect(env.photos.galleryCalls, 1);
      expect(find.text('No image taken'), findsNothing);
    });

    testWidgets('cancelling the camera keeps the form unchanged', (tester) async {
      final env = TestEnv();
      env.photos.result = null;
      await openForm(tester, env);

      await tester.tap(find.text('Take Picture'));
      await tester.pumpAndSettle();

      expect(find.text('No image taken'), findsOneWidget);
    });

    testWidgets('a location problem is explained to the user', (tester) async {
      final env = TestEnv();
      env.location.error = 'Location permission was denied.';
      await openForm(tester, env);

      await tester.tap(find.text('Get Current Location'));
      await tester.pumpAndSettle();

      expect(find.text('Location permission was denied.'), findsOneWidget);
      expect(find.text('No location chosen'), findsOneWidget);
    });

    testWidgets('a complete form is saved and the place appears in the list', (tester) async {
      final env = TestEnv();
      await openForm(tester, env);

      await tester.enterText(find.byType(TextFormField), '  Fjord view ');
      await tester.tap(find.text('Take Picture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Current Location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Place'));
      await tester.pumpAndSettle();

      // Back on the list, with the new place and a confirmation.
      expect(find.byType(AddPlaceScreen), findsNothing);
      expect(find.text('Fjord view'), findsOneWidget);
      expect(find.text('"Fjord view" added to your places'), findsOneWidget);
      expect(env.repository.places.single.title, 'Fjord view');
      expect(env.repository.places.single.location.latitude, 62.4722);
      expect(env.imageStore.saved, hasLength(1));
    });

    testWidgets('a failed save keeps the form open and says so', (tester) async {
      final env = TestEnv();
      await openForm(tester, env);
      env.repository.failWrites = true;

      await tester.enterText(find.byType(TextFormField), 'Fjord view');
      await tester.tap(find.text('Take Picture'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Current Location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Place'));
      await tester.pumpAndSettle();

      expect(find.byType(AddPlaceScreen), findsOneWidget);
      expect(find.text('Could not save the place. Try again.'), findsOneWidget);
    });
  });

  group('place detail', () {
    testWidgets('shows the title, address and coordinates', (tester) async {
      final place = makePlace('Fjord view', address: 'Fjord Road 1');
      await pumpApp(tester, TestEnv(places: [place]), PlaceDetailScreen(place: place));

      expect(find.text('Fjord view'), findsOneWidget);
      expect(find.text('Fjord Road 1'), findsOneWidget);
      expect(find.text('62.4700° N, 6.1500° E'), findsOneWidget);
    });

    testWidgets('does not repeat the coordinates when they are the address', (tester) async {
      final place = makePlace('Fjord view', address: '62.4700° N, 6.1500° E');
      await pumpApp(tester, TestEnv(places: [place]), PlaceDetailScreen(place: place));

      expect(find.text('62.4700° N, 6.1500° E'), findsOneWidget);
    });

    testWidgets('the heart on the detail screen updates', (tester) async {
      final place = makePlace('Fjord view');
      final env = TestEnv(places: [place]);
      await pumpApp(tester, env, PlaceDetailScreen(place: place));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlaceDetailScreen)),
      );
      await container.read(userPlacesProvider.notifier).loadPlaces();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add to favorites'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
      expect(env.repository.places.single.isFavorite, isTrue);
    });
  });

  group('map screen', () {
    testWidgets('asks for a tap, then offers to use the chosen point', (tester) async {
      await pumpApp(tester, TestEnv(), const MapScreen(isSelecting: true));

      expect(find.text('Pick your Location'), findsOneWidget);
      expect(find.text('Tap the map to drop a pin'), findsOneWidget);
      expect(find.text('Use this location'), findsNothing);

      await tester.tap(find.byType(FlutterMap));
      // flutter_map waits a moment to tell a tap from a double tap.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Use this location'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('viewing a place is titled "Your Location" and names the place', (tester) async {
      await pumpApp(
        tester,
        TestEnv(),
        MapScreen(
          initialLocation: makePlace('Fjord view').location,
          markerTitle: 'Fjord view',
        ),
      );

      expect(find.text('Your Location'), findsOneWidget);
      expect(find.text('Fjord view'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('zoom buttons are there', (tester) async {
      await pumpApp(tester, TestEnv(), const MapScreen());

      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
