import 'package:flutter/material.dart';
import 'package:location/location.dart';

class PermissionStatusWidget extends StatefulWidget {
  const PermissionStatusWidget({super.key});

  @override
  _PermissionStatusState createState() => _PermissionStatusState();
}

class _PermissionStatusState extends State<PermissionStatusWidget> {
  final Location location = Location();

  PermissionStatus? _permissionGranted;

  Future<void> _checkPermissions() async {
    final permissionGrantedResult = await location.hasPermission();
    setState(() {
      _permissionGranted = permissionGrantedResult;
    });
  }

  Future<void> _requestPermission() async {
    if (_permissionGranted != PermissionStatus.granted) {
      final permissionRequestedResult = await location.requestPermission();
      setState(() {
        _permissionGranted = permissionRequestedResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Permission status: ${_permissionGranted ?? "unknown"}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 42),
              child: ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Check'),
              ),
            ),
            ElevatedButton(
              onPressed: _permissionGranted == PermissionStatus.granted
                  ? null
                  : _requestPermission,
              child: const Text('Request'),
            )
          ],
        )
      ],
    );
  }
}
