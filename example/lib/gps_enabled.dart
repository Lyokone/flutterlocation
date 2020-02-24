import 'package:flutter/material.dart';
import 'package:location/location.dart';

class GpsEnabledWidget extends StatefulWidget {
  GpsEnabledWidget({key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GpsEnabledState();
}

class _GpsEnabledState extends State<GpsEnabledWidget> {
  final Location location = new Location();

  bool _isGpsEnabled;

  _checkService() async {
    bool isGpsEnabledResult = await location.isGpsEnabled();
    setState(() {
      _isGpsEnabled = isGpsEnabledResult;
    });
  }

  _requestService() async {
    if (_isGpsEnabled == null || !_isGpsEnabled) {
      bool serviceRequestedResult = await location.requestService();
      setState(() {
        _isGpsEnabled = serviceRequestedResult;
      });
      if (!serviceRequestedResult) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Hardware Gps enabled: ${_isGpsEnabled ?? "unknown"}',
            style: Theme.of(context).textTheme.body2),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 42),
              child: RaisedButton(
                child: Text("Check"),
                onPressed: _checkService,
              ),
            ),
            RaisedButton(
              child: Text("Request"),
              onPressed: _isGpsEnabled == true ? null : _requestService,
            )
          ],
        )
      ],
    );
  }
}
