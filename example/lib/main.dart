import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String,double> _currentLocation;
  StreamSubscription<Map<String,double>> _locationSubscription;
  Location _location = new Location();

  @override
  initState() {
    super.initState();
    initPlatformState();
    _locationSubscription =
        _location.onLocationChanged.listen((Map<String,double> result) {
          setState(() {
            _currentLocation = result;
          });
        });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    Map<String,double> location;
    // Platform messages may fail, so we use a try/catch PlatformException.


    try {
      location = await _location.getLocation;
    } on PlatformException {
      location = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted)
      return;

    setState(() {
      _currentLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new Center(
          child: new Text('Location : $_currentLocation\n'),
        ),
      ),
    );
  }
}
