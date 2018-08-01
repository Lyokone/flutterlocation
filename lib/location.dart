import 'dart:async';

import 'package:flutter/services.dart';

class Location {
  static const MethodChannel _channel = const MethodChannel('lyokone/location');
  static const EventChannel _stream = const EventChannel('lyokone/locationstream');

  Stream<Map<String,double>> _onLocationChanged;

  Future<Map<String, double>> get getLocation => _channel
      .invokeMethod('getLocation')
      .then((result) => result.cast<String, double>());

  Stream<Map<String, double>> get onLocationChanged {
    if (_onLocationChanged == null) {
      _onLocationChanged = _stream
          .receiveBroadcastStream()
          .map<Map<String, double>>(
              (element) => element.cast<String, double>());
    }
    return _onLocationChanged;
  }

  static Future<bool> hasPermission() async
  {
    final int permission = await _channel.invokeMethod('hasPermission');
    return (permission == 1);
  }
}
