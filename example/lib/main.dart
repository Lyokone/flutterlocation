import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import 'get_location.dart';
import 'listen_location.dart';
import 'permission_status.dart';
import 'service_enabled.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Location',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: MyHomePage(title: 'Flutter Location Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Location location = new Location();

  _showInfoDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Demo Application'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Created by Guillaume Bernos'),
                InkWell(
                  child: Text(
                    'https://github.com/Lyokone/flutterlocation',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTap: () =>
                      launch("https://github.com/Lyokone/flutterlocation"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          children: <Widget>[
            PermissionStatusWidget(),
            Divider(
              height: 32,
            ),
            ServiceEnabledWidget(),
            Divider(
              height: 32,
            ),
            GetLocationWidget(),
            Divider(
              height: 32,
            ),
            ListenLocationWidget()
          ],
        ),
      ),
    );
  }
}
