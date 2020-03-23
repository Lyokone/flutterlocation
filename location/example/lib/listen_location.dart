import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ListenLocationWidget extends StatefulWidget {
  ListenLocationWidget({Key key}) : super(key: key);

  @override
  _ListenLocationState createState() => _ListenLocationState();
}

class _ListenLocationState extends State<ListenLocationWidget> {
  final Location location = new Location();

  LocationData _location;
  StreamSubscription<LocationData> _locationSubscription;
  String _error;

  _listenLocation() async {
    _locationSubscription = location.onLocationChanged().handleError((err) {
      setState(() {
        _error = err.code;
      });
      _locationSubscription.cancel();
    }).listen((LocationData currentLocation) {
      setState(() {
        _error = null;

        _location = currentLocation;
      });
    });
  }

  _stopListen() async {
    _locationSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Listen location: ' + (_error ?? '${_location ?? "unknown"}'),
          style: Theme.of(context).textTheme.body2,
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 42),
              child: RaisedButton(
                child: Text("Listen"),
                onPressed: _listenLocation,
              ),
            ),
            RaisedButton(
              child: Text("Stop"),
              onPressed: _stopListen,
            )
          ],
        ),
      ],
    );
  }
}
