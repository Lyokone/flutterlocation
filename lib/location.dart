import 'dart:async';

import 'package:flutter/services.dart';

class Location {
  static const MethodChannel _channel = const MethodChannel('lyokone/location');
  static const EventChannel _stream = const EventChannel('lyokone/locationstream');

  Stream<Map<String,double>> _onLocationChanged;

  Future<dynamic> get getLocation =>
      _channel.invokeMethod('getLocation');

  Stream<Map<String,double>> get onLocationChanged {
    if (_onLocationChanged == null) {
      _onLocationChanged =
          _stream.receiveBroadcastStream();
    }
    return _onLocationChanged;
  }
}
