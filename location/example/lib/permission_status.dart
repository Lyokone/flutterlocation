import 'package:flutter/material.dart';
import 'package:location/location.dart';

class PermissionStatusWidget extends StatefulWidget {
  PermissionStatusWidget({Key key}) : super(key: key);

  @override
  _PermissionStatusState createState() => _PermissionStatusState();
}

class _PermissionStatusState extends State<PermissionStatusWidget> {
  final Location location = new Location();

  PermissionStatus _permissionGranted;

  _checkPermissions() async {
    PermissionStatus permissionGrantedResult = await location.hasPermission();
    setState(() {
      _permissionGranted = permissionGrantedResult;
    });
  }

  _requestPermission() async {
    if (_permissionGranted != PermissionStatus.GRANTED) {
      PermissionStatus permissionRequestedResult =
          await location.requestPermission();
      setState(() {
        _permissionGranted = permissionRequestedResult;
      });
      if (permissionRequestedResult != PermissionStatus.GRANTED) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Permission status: ${_permissionGranted ?? "unknown"}',
          style: Theme.of(context).textTheme.body2,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 42),
              child: RaisedButton(
                child: Text("Check"),
                onPressed: _checkPermissions,
              ),
            ),
            RaisedButton(
              child: Text("Request"),
              onPressed: _permissionGranted == PermissionStatus.GRANTED
                  ? null
                  : _requestPermission,
            )
          ],
        )
      ],
    );
  }
}
