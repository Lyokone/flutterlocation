import 'package:flutter/material.dart';
import 'package:location_example/change_notification.dart';
import 'package:location_example/change_settings.dart';
import 'package:location_example/get_location.dart';
import 'package:location_example/listen_location.dart';
import 'package:location_example/permission_status.dart';
import 'package:location_example/service_enabled.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Location',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: 'Flutter Location Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, this.title});
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const <Widget>[
            SizedBox(height: 16),
            PermissionStatusWidget(),
            Divider(height: 32),
            ServiceEnabledWidget(),
            Divider(height: 32),
            GetLocationWidget(),
            Divider(height: 32),
            ListenLocationWidget(),
            Divider(height: 32),
            ChangeSettings(),
            Divider(height: 32),
            ChangeNotificationWidget()
          ],
        ),
      ),
    );
  }
}
