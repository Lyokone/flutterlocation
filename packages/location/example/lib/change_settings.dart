import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ChangeSettings extends StatefulWidget {
  const ChangeSettings({super.key});

  @override
  State<ChangeSettings> createState() => _ChangeSettingsState();
}

class _ChangeSettingsState extends State<ChangeSettings> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _intervalController = TextEditingController(
    text: '5000',
  );

  final TextEditingController _distanceFilterController = TextEditingController(
    text: '0',
  );

  LocationAccuracy _locationAccuracy = LocationAccuracy.high;

  bool _useGooglePlayServices = false;

  @override
  void dispose() {
    _intervalController.dispose();
    _distanceFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Change settings',
              style: Theme.of(context).textTheme.bodyText1,
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
              onChanged: (LocationAccuracy? value) {
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
            SwitchListTile(
              value: _useGooglePlayServices,
              title: const Text('Use Google Play Services'),
              onChanged: (value) {
                setState(() {
                  _useGooglePlayServices = value;
                });
              },
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {
                setLocationSettings(
                  useGooglePlayServices: _useGooglePlayServices,
                  interval: double.parse(_intervalController.text),
                  accuracy: _locationAccuracy,
                  smallestDisplacement:
                      double.parse(_distanceFilterController.text),
                );
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}
