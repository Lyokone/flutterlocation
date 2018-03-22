import 'dart:async';

import 'package:flutter/services.dart';

class Location {
  static const MethodChannel _channel = const MethodChannel('lyokone/location');
  static const EventChannel _stream = const EventChannel('lyokone/locationstream');

  Stream<Map<String,double>> _onLocationChanged;

  Future<Map<String,double>> get getLocation async {
    var res = await _channel.invokeMethod('getLocation');
    if (res is Map) {
      return new Map<String, double>.from(res);
    } else {
      return null;
    }
  }

  Stream<Map<String,double>> get onLocationChanged {
    if (_onLocationChanged == null) {
      var receiveBroadcastStream = _stream.receiveBroadcastStream();
      if (receiveBroadcastStream is Stream) {
        _onLocationChanged = Stream.castFrom(receiveBroadcastStream);
      }
    }
    return _onLocationChanged;
  }
}
