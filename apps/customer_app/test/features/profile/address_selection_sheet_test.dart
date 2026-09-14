import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_phoenix_customer/core/services/location_service.dart';
import 'package:project_phoenix_customer/features/profile/presentation/widgets/address_selection_sheet.dart';
import 'package:shared_theme/shared_theme.dart';

class FakeLocationService extends LocationService {
  @override
  Future<Map<String, dynamic>> getCurrentLocation({int attempt = 1}) async {
    return {
      'latitude': 13.0827,
      'longitude': 80.2707,
      'accuracy': 15.0,
    };
  }

  @override
  Future<Map<String, String>> reverseGeocode(double latitude, double longitude) async {
    return {
      'houseNumber': 'Flat 101',
      'street': 'Anna Salai',
      'area': 'Guindy',
      'city': 'Chennai',
      'state': 'Tamil Nadu',
      'pincode': '600032',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AddressSelectionSheet Layout and Constraint Tests', () {
    testWidgets('Renders properly with AppTheme.lightTheme without infinite width crash',
        (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(fakeLocationService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AddressSelectionSheet(
                initialAddress: '123 Test St',
                initialCity: 'Chennai',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify header and form fields render
      expect(find.text('Change Saved Address'), findsOneWidget);
      expect(find.text('Use Current GPS Location'), findsOneWidget);

      // Verify the Locate Me button is found and has finite width
      final locateMeFinder = find.widgetWithText(ElevatedButton, 'Locate Me');
      expect(locateMeFinder, findsOneWidget);

      final Size buttonSize = tester.getSize(locateMeFinder);
      expect(buttonSize.width.isFinite, isTrue);
      expect(buttonSize.width, greaterThan(50));
      expect(buttonSize.width, lessThanOrEqualTo(130));

      // Verify no BoxConstraints forces an infinite width exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders properly with AppTheme.highContrastTheme without infinite width crash',
        (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(fakeLocationService),
          ],
          child: MaterialApp(
            theme: AppTheme.highContrastTheme,
            home: const Scaffold(
              body: AddressSelectionSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Set Your Address'), findsOneWidget);
      final locateMeFinder = find.widgetWithText(ElevatedButton, 'Locate Me');
      expect(locateMeFinder, findsOneWidget);

      final Size buttonSize = tester.getSize(locateMeFinder);
      expect(buttonSize.width.isFinite, isTrue);
      expect(buttonSize.width, lessThanOrEqualTo(130));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Locate Me updates address fields successfully without layout error',
        (WidgetTester tester) async {
      final fakeLocationService = FakeLocationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(fakeLocationService),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AddressSelectionSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      final locateMeFinder = find.widgetWithText(ElevatedButton, 'Locate Me');
      await tester.tap(locateMeFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // After reverse geocode resolution
      expect(find.text('Chennai'), findsWidgets);
      expect(find.text('Anna Salai'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
