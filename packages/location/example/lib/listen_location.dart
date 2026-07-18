import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class ListenLocationWidget extends StatefulWidget {
  const ListenLocationWidget({super.key});

  @override
  _ListenLocationState createState() => _ListenLocationState();
}

class _ListenLocationState extends State<ListenLocationWidget> {
  final Location location = Location();

  LocationData? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _error;

  Future<void> _listenLocation() async {
    _locationSubscription =
        location.onLocationChanged.handleError((dynamic err) {
      if (err is PlatformException) {
        setState(() {
          _error = err.code;
        });
      }
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((currentLocation) {
      setState(() {
        _error = null;

        _location = currentLocation;
      });
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
    // No setState() here: the element is already being torn down by the
    // time dispose() runs, and calling setState() on a defunct element
    // throws (caught by an e2e test exercising a widget teardown mid-stream
    // for the first time -- this had gone unnoticed since nothing had ever
    // unmounted this widget with an active subscription before).
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Listen location: ${_error ?? '${_location ?? "unknown"}'}',
          key: const Key('listenLocationText'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 42),
              child: ElevatedButton(
                key: const Key('listenLocationButton'),
                onPressed:
                    _locationSubscription == null ? _listenLocation : null,
                child: const Text('Listen'),
              ),
            ),
            ElevatedButton(
              key: const Key('stopListenLocationButton'),
              onPressed: _locationSubscription != null ? _stopListen : null,
              child: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }
}
