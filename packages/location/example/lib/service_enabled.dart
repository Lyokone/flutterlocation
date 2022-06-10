import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ServiceEnabledWidget extends StatefulWidget {
  const ServiceEnabledWidget({super.key});

  @override
  State<ServiceEnabledWidget> createState() => _ServiceEnabledWidgetState();
}

class _ServiceEnabledWidgetState extends State<ServiceEnabledWidget> {
  bool? _serviceEnabled;

  bool? _networkEnabled;

  Future<void> _checkService() async {
    final serviceEnabledResult = await isGPSEnabled();
    setState(() {
      _serviceEnabled = serviceEnabledResult;
    });
  }

  Future<void> _checkNetworkService() async {
    final serviceEnabledResult = await isNetworkEnabled();
    setState(() {
      _networkEnabled = serviceEnabledResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'GPS enabled: ${_serviceEnabled ?? "unknown"}',
            style: Theme.of(context).textTheme.bodyText1,
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
            ],
          ),
          Text(
            'Service enabled: ${_networkEnabled ?? "unknown"}',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Row(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(right: 42),
                child: ElevatedButton(
                  onPressed: _checkNetworkService,
                  child: const Text('Check'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
