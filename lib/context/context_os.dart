/// @nodoc
library context_os;

import 'dart:io' show Platform;

import 'package:device_info/device_info.dart' show DeviceInfoPlugin;

import '../util/util.dart' show debugError;

/// @nodoc
Future<Map<String, dynamic>> contextOS() async {
  try {
    return Platform.isAndroid ? _contextAndroid() : _contextIOS();
  } catch (e, s) {
    debugError(e, s);

    return <String, dynamic>{};
  }
}

Future<Map<String, dynamic>> _contextAndroid() async {
  final info = await DeviceInfoPlugin().androidInfo;

  final release = info.version.release;
  final apiLevel = info.version.sdkInt;

  return {'name': 'Android', 'version': '$release (API level $apiLevel)'};
}

Future<Map<String, dynamic>> _contextIOS() async {
  final info = await DeviceInfoPlugin().iosInfo;

  return {'name': info.systemName, 'version': info.systemVersion};
}
