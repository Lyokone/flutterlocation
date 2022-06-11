import 'package:flutter/material.dart';
import 'package:location/location.dart';

class PermissionStatusWidget extends StatefulWidget {
  const PermissionStatusWidget({super.key});

  @override
  State<PermissionStatusWidget> createState() => _PermissionStatusWidgetState();
}

class _PermissionStatusWidgetState extends State<PermissionStatusWidget> {
  PermissionStatus? _permissionGranted;

  Future<void> _checkPermissions() async {
    final permissionGrantedResult = await getPermissionStatus();
    setState(() {
      _permissionGranted = permissionGrantedResult;
    });
  }

  Future<void> _requestPermission() async {
    if (_permissionGranted != PermissionStatus.granted) {
      final permissionRequestedResult = await requestPermission();
      setState(() {
        _permissionGranted = permissionRequestedResult;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Permission status: ${_permissionGranted ?? "unknown"}',
            style: Theme.of(context).textTheme.bodyText1,
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
      ),
    );
  }
}
