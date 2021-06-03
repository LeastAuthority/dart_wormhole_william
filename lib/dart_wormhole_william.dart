import 'dart:async';

import 'package:flutter/services.dart';

class DartWormholeWilliam {
  static const MethodChannel _channel =
      const MethodChannel('dart_wormhole_william');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
