import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class ListenLocationWidget extends StatefulWidget {
  const ListenLocationWidget({super.key});

  @override
  State<ListenLocationWidget> createState() => _ListenLocationWidgetState();
}

class _ListenLocationWidgetState extends State<ListenLocationWidget> {
  LocationData? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _error;

  bool _inBackground = false;

  Future<void> _listenLocation() async {
    _locationSubscription = onLocationChanged(inBackground: _inBackground)
        .handleError((dynamic err) {
      if (err is PlatformException) {
        setState(() {
          _error = err.code;
        });
      }
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((LocationData currentLocation) async {
      setState(() {
        _error = null;

        _location = currentLocation;
      });
      await updateBackgroundNotification(
        subtitle:
            'Location: ${currentLocation.latitude}, ${currentLocation.longitude}',
        onTapBringToFront: true,
      );
    });
    setState(() {});
  }

  Future<void> _stopListen() async {
    await _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _error ??
                '''
Listen location: ${_location?.latitude}, ${_location?.longitude}
                ''',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Row(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 42),
                child: ElevatedButton(
                  onPressed:
                      _locationSubscription == null ? _listenLocation : null,
                  child: const Text('Listen'),
                ),
              ),
              ElevatedButton(
                onPressed: _locationSubscription != null ? _stopListen : null,
                child: const Text('Stop'),
              )
            ],
          ),
          SwitchListTile(
            value: _inBackground,
            title: const Text('Get location in background'),
            onChanged: (value) {
              setState(() {
                _inBackground = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
