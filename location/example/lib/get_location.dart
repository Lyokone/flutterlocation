import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class GetLocationWidget extends StatefulWidget {
  GetLocationWidget({Key key}) : super(key: key);

  @override
  _GetLocationState createState() => _GetLocationState();
}

class _GetLocationState extends State<GetLocationWidget> {
  final Location location = new Location();

  LocationData _location;
  String _error;

  _getLocation() async {
    setState(() {
      _error = null;
    });
    try {
      var _locationResult = await location.getLocation();
      setState(() {
        _location = _locationResult;
      });
    } on PlatformException catch (err) {
      setState(() {
        _error = err.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Location: ' + (_error ?? '${_location ?? "unknown"}'),
          style: Theme.of(context).textTheme.body2,
        ),
        Row(
          children: [
            RaisedButton(
              child: Text("Get"),
              onPressed: _getLocation,
            )
          ],
        ),
      ],
    );
  }
}
