import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class ChangeNotificationWidget extends StatefulWidget {
  const ChangeNotificationWidget({super.key});

  @override
  _ChangeNotificationWidgetState createState() =>
      _ChangeNotificationWidgetState();
}

class _ChangeNotificationWidgetState extends State<ChangeNotificationWidget> {
  final Location _location = Location();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _channelController = TextEditingController(
    text: 'Location background service',
  );
  final TextEditingController _titleController = TextEditingController(
    text: 'Location background service running',
  );

  String? _iconName = 'navigation_empty_icon';

  @override
  void dispose() {
    _channelController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const Text(
        'Change notification settings not available on this platform',
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Android Notification Settings',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _channelController,
            decoration: const InputDecoration(
              labelText: 'Channel Name',
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: _iconName,
            onChanged: (value) {
              setState(() {
                _iconName = value;
              });
            },
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'navigation_empty_icon',
                child: Text('Empty'),
              ),
              DropdownMenuItem<String>(
                value: 'circle',
                child: Text('Circle'),
              ),
              DropdownMenuItem<String>(
                value: 'square',
                child: Text('Square'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () {
              _location.changeNotificationOptions(
                channelName: _channelController.text,
                title: _titleController.text,
                iconName: _iconName,
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
