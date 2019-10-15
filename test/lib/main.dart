// ignore_for_file: unawaited_futures

/// @nodoc
library test_app;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_analytics/flutter_analytics.dart';
import 'package:flutter_analytics/version_control.dart';

import 'package:flutter_driver/driver_extension.dart';

/// @nodoc
void main() {
  enableFlutterDriverExtension();
  runApp(_MyApp());
}

const _org = 'integrationTests';

class _MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  String txt1 = '', txt2 = '', txt3 = '';

  bool localEnabled = true, remoteEnabled = true, tputEnabled = true;

  Future<String> localTest() async {
    Analytics.setup(orgId: _org);

    Analytics.flush((_) async => true);

    Analytics.group('testGroupId', {'numTrait': 7, 'txtTrait': 'tGroup'});
    Analytics.identify('');
    Analytics.screen('Test Screen', {'numProp': 5, 'txtProp': 'pScreen'});
    Analytics.track('Test Event', {'numProp': 3, 'txtProp': 'pTrack'});

    await Analytics.flush((batch) async {
      assert(batch.length == 4);

      for (int i = 0; i < 4; ++i) {
        final evt = batch[i];
        final Map<String, dynamic> props = evt['properties'] ?? evt['traits'];

        assertEventCore(evt);

        if (i >= 0) {
          assert(evt['userId'] == '');

          assert(evt['anonymousId'] == batch.first['anonymousId']);

          final Map<String, dynamic> firstSdk = batch.first['traits']['sdk'];
          assert(props['sdk']['sessionId'] == firstSdk['sessionId']);
          assert(props['sdk']['setupId'] == firstSdk['setupId']);
        }

        assert(props['orgId'] == _org);

        switch (i) {
          case 0:
            assert(evt['type'] == 'group');
            assert(evt['traits']['numTrait'].toString() == '7');
            assert(evt['traits']['txtTrait'].toString() == 'tGroup');
            break;

          case 1:
            assert(evt['type'] == 'identify');
            assert((evt['traits'] as Map<String, dynamic>).keys.length == 2);
            break;

          case 2:
            assert(evt['type'] == 'screen');
            assert(evt['properties']['numProp'].toString() == '5');
            assert(evt['properties']['txtProp'].toString() == 'pScreen');
            break;

          case 3:
            assert(evt['type'] == 'track');
            assert(evt['properties']['numProp'].toString() == '3');
            assert(evt['properties']['txtProp'].toString() == 'pTrack');
            break;
        }
      }

      return true;
    });

    return 'local test completed successfully';
  }

  Future<String> remoteTest() async {
    final batches = <List<Map<String, dynamic>>>[];

    final onFlush = (List<Map<String, dynamic>> batch) => batches.add(batch);

    Analytics.setup(onFlush: onFlush, orgId: _org);

    Analytics.flush();

    Analytics.group('myGroupIdGoesHere');

    Analytics.identify(
        '5c903bce-6fa8-4501-9bfd-7bc52a851aec', <String, dynamic>{
      'birthday': '1997-01-18T00:00:00.000000Z',
      'createdAt': '2018-05-04T14:13:28.941000Z',
      'gender': 'fluid',
    });

    Analytics.screen('Post Viewer', <String, dynamic>{
      'url': 'app://deeplink.myapp/post/5b450fd6504f3fec66bb99bc?src=push'
    });

    Analytics.track('Some Event');

    Analytics.track('Application Backgrounded', <String, dynamic>{
      'url': 'app://deeplink.myapp/post/5b450fd6504f3fec66bb99bc?src=push'
    });

    Analytics.flush();

    while (batches.length < 2) {
      await Future<void>.delayed(Duration(seconds: 1));
    }

    // may implicate in false negatives for edge cases
    assert(batches.last.length >= 5);

    return 'remote test completed successfully';
  }

  Future<String> throughputTest() async {
    final t0 = DateTime.now();

    int _evtCnt = 0;

    final onFlush = (List<Map<String, dynamic>> b) => _evtCnt += b.length;

    Analytics.setup(onFlush: onFlush, orgId: _org);

    for (;;) {
      Analytics.track('Load Test Event');

      if (_evtCnt >= 10000) {
        break;
      }

      await Future.delayed(Duration(microseconds: 100));
    }

    final int eventCount = _evtCnt;
    final t1 = DateTime.now();

    final eventTput = eventCount / t1.difference(t0).inSeconds;
    print('throughput: ${eventTput.toStringAsFixed(2)} eps');

    assert(eventTput >= 20.0);

    return 'throughput test completed successfully';
  }

  @override
  Widget build(_) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: Text('Integration Test')),
            body: bodyBuilder(),
            bottomNavigationBar: BottomAppBar(child: Row())));
  }

  Widget bodyBuilder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('LOCAL TEST'),
          IconButton(
              key: Key('local'),
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                if (!localEnabled) {
                  return;
                }
                localEnabled = false;

                localTest()
                    .then((res) => setState(() => txt1 = res))
                    .catchError((dynamic e) => setState(() => txt1 = '$e'))
                    .whenComplete(() => setState(() => localEnabled = true));
              }),
          Text(txt1, key: Key('txt1')),
          Divider(),
          Text('REMOTE TEST'),
          IconButton(
              key: Key('remote'),
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                if (!remoteEnabled) {
                  return;
                }
                remoteEnabled = false;

                remoteTest()
                    .then((res) => setState(() => txt2 = res))
                    .catchError((dynamic e) => setState(() => txt2 = '$e'))
                    .whenComplete(() => setState(() => remoteEnabled = true));
              }),
          Text(txt2, key: Key('txt2')),
          Divider(),
          Text('THROUGHPUT TEST'),
          IconButton(
              key: Key('throughput'),
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                if (!tputEnabled) {
                  return;
                }
                tputEnabled = false;

                throughputTest()
                    .then((res) => setState(() => txt3 = res))
                    .catchError((dynamic e) => setState(() => txt3 = '$e'))
                    .whenComplete(() => setState(() => tputEnabled = true));
              }),
          Text(txt3, key: Key('txt3'))
        ],
      ),
    );
  }

  void assertEventCore(Map<String, dynamic> event) {
    assert(event['anonymousId'].toString().length == 44);

    final Map<String, dynamic> context = event['context'];

    assert(context['app']['build'].toString() == '8');
    assert(context['app']['version'] == '5.6.7');

    final Map<String, dynamic> device = context['device'];

    if (Platform.isIOS) {
      assert(device['id'].toString().length == 36);
      assert(device['manufacturer'].toString().toLowerCase() == 'apple');
      assert(device['model'] == 'iPhone');
      assert(device['name'].contains('iPhone'));
      assert(context['os']['name'] == 'iOS');
    }

    assert(context['groupId'] == 'testGroupId');

    assert(context['library']['name'] == sdkName);
    assert(context['library']['version'] == sdkVersion);

    assert(context['network']['cellular'] || true);
    assert(context['network']['wifi'] || true);

    assert(event['messageId'].toString().length == 36);
    assert(DateTime.parse(event['timestamp']).isBefore(DateTime.now()));

    final Map<String, dynamic> props = event['properties'] ?? event['traits'];

    assert(props['sdk']['dartEnv'] == 'DEVELOPMENT');
    assert(props['sdk']['sessionId'].toString().length == 36);
    assert(props['sdk']['setupId'].toString().length == 36);
    assert(int.tryParse(props['sdk']['tzOffsetHours'].toString()) >= -12);
    assert(int.tryParse(props['sdk']['tzOffsetHours'].toString()) <= 12);
  }
}
