import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ServiceEnabledWidget extends StatefulWidget {
  const ServiceEnabledWidget({super.key});

  @override
  _ServiceEnabledState createState() => _ServiceEnabledState();
}

class _ServiceEnabledState extends State<ServiceEnabledWidget> {
  final Location location = Location();

  bool? _serviceEnabled;

  Future<void> _checkService() async {
    final serviceEnabledResult = await location.serviceEnabled();
    setState(() {
      _serviceEnabled = serviceEnabledResult;
    });
  }

  Future<void> _requestService() async {
    if (_serviceEnabled ?? false) {
      return;
    }

    final serviceRequestedResult = await location.requestService();
    setState(() {
      _serviceEnabled = serviceRequestedResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Service enabled: ${_serviceEnabled ?? "unknown"}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 42),
              child: ElevatedButton(
                onPressed: _checkService,
                child: const Text('Check'),
              ),
            ),
            ElevatedButton(
              onPressed: (_serviceEnabled ?? false) ? null : _requestService,
              child: const Text('Request'),
            )
          ],
        )
      ],
    );
  }
}
