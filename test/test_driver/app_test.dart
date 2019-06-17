import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

const oneSec = Duration(seconds: 1);
const tenSecs = Duration(seconds: 10);

void main() {
  group('Integration Test App', () {
    final txt1Finder = find.byValueKey('txt1');
    final txt2Finder = find.byValueKey('txt2');
    final txt3Finder = find.byValueKey('txt3');

    final remoteFinder = find.byValueKey('remote');
    final localFinder = find.byValueKey('local');
    final tputFinder = find.byValueKey('throughput');

    FlutterDriver driver;

    setUpAll(() async {
      driver ??= await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('run local test', () async {
      await driver.tap(localFinder, timeout: tenSecs);

      bool success = false;

      while (true) {
        final txt = await driver.getText(txt1Finder, timeout: tenSecs);

        if (txt.contains('success')) {
          success = true;
          break;
        }

        if (txt != '') {
          success = false;
          break;
        }

        await Future<void>.delayed(oneSec);
      }

      expect(success, true);
    });

    test('run remote test', () async {
      await driver.tap(remoteFinder, timeout: tenSecs);

      bool success = false;

      while (true) {
        final txt = await driver.getText(txt2Finder, timeout: tenSecs);

        if (txt.contains('success')) {
          success = true;
          break;
        }

        if (txt != '') {
          success = false;
          break;
        }

        await Future<void>.delayed(oneSec);
      }

      expect(success, true);
    });

    test('run throughput test', () async {
      await driver.tap(tputFinder, timeout: tenSecs);

      bool success = false;

      while (true) {
        final txt = await driver.getText(txt3Finder, timeout: tenSecs);

        if (txt.contains('success')) {
          success = true;
          break;
        }

        if (txt != '') {
          success = false;
          break;
        }

        await Future<void>.delayed(oneSec);
      }

      expect(success, true);
    }, timeout: Timeout(Duration(minutes: 9)));
  }, timeout: Timeout(Duration(minutes: 10)));
}
