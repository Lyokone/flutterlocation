import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ChangeSettings extends StatefulWidget {
  const ChangeSettings({super.key});

  @override
  _ChangeSettingsState createState() => _ChangeSettingsState();
}

class _ChangeSettingsState extends State<ChangeSettings> {
  final Location _location = Location();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _intervalController = TextEditingController(
    text: '5000',
  );
  final TextEditingController _distanceFilterController = TextEditingController(
    text: '0',
  );

  LocationAccuracy _locationAccuracy = LocationAccuracy.high;

  @override
  void dispose() {
    _intervalController.dispose();
    _distanceFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Change settings',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          TextFormField(
            keyboardType: TextInputType.number,
            controller: _intervalController,
            decoration: const InputDecoration(
              labelText: 'Interval',
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            keyboardType: TextInputType.number,
            controller: _distanceFilterController,
            decoration: const InputDecoration(
              labelText: 'DistanceFilter',
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<LocationAccuracy>(
            value: _locationAccuracy,
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _locationAccuracy = value;
              });
            },
            items: const <DropdownMenuItem<LocationAccuracy>>[
              DropdownMenuItem(
                value: LocationAccuracy.high,
                child: Text('High'),
              ),
              DropdownMenuItem(
                value: LocationAccuracy.balanced,
                child: Text('Balanced'),
              ),
              DropdownMenuItem(
                value: LocationAccuracy.low,
                child: Text('Low'),
              ),
              DropdownMenuItem(
                value: LocationAccuracy.powerSave,
                child: Text('Powersave'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () {
              _location.changeSettings(
                accuracy: _locationAccuracy,
                interval: int.parse(_intervalController.text),
                distanceFilter: double.parse(_distanceFilterController.text),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
