import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class EnableInBackgroundWidget extends StatefulWidget {
  const EnableInBackgroundWidget({super.key});

  @override
  _EnableInBackgroundState createState() => _EnableInBackgroundState();
}

class _EnableInBackgroundState extends State<EnableInBackgroundWidget> {
  final Location location = Location();

  bool? _enabled;
  String? _error;

  @override
  void initState() {
    _checkBackgroundMode();
    super.initState();
  }

  Future<void> _checkBackgroundMode() async {
    setState(() {
      _error = null;
    });
    final result = await location.isBackgroundModeEnabled();
    setState(() {
      _enabled = result;
    });
  }

  Future<void> _toggleBackgroundMode() async {
    setState(() {
      _error = null;
    });
    try {
      final result =
          await location.enableBackgroundMode(enable: !(_enabled ?? false));
      setState(() {
        _enabled = result;
      });
    } on PlatformException catch (err) {
      setState(() {
        _error = err.code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Text('Enable in background not available on the web');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Enabled in background: ${_error ?? '${_enabled ?? false}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 42),
              child: ElevatedButton(
                onPressed: _checkBackgroundMode,
                child: const Text('Check'),
              ),
            ),
            ElevatedButton(
              onPressed: _enabled == null ? null : _toggleBackgroundMode,
              child: Text(_enabled ?? false ? 'Disable' : 'Enable'),
            )
          ],
        )
      ],
    );
  }
}
