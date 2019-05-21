import 'package:flutter/material.dart';
import 'dart:async';

import 'package:upnp/upnp.dart';

import 'therma.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Therma',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
//      home: MyHomePage(),
      home: ThermaPage(address: '192.168.5.133')
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _itemsLoaded = false;
  List<String> devices = [];

  void _discoverDevices() async {
    DeviceDiscoverer discov = new DeviceDiscoverer();
    List<DiscoveredDevice> devices = await discov.discoverDevices();
    print(devices);
  }

  @override
  void initState() {
    _discoverDevices();
    new Timer(new Duration(seconds: 3), () {
      this._itemsLoaded = true;
    });
    super.initState();
//    Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) {
//      return new ThermaPage(address: '192');
//    }));
  }

  void _loadControl(String item) {
    print(item);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = ListTile.divideTiles(
        context: context,
        tiles: ['asd', 'basd']
            .map((String el) => Ink(child: ListTile(title: Text(el), onTap: () => _loadControl(el),)))).toList();
    return Scaffold(
      appBar: new AppBar(title: new Text('Discovered thermostats')),
      body: this._itemsLoaded
          ? new ListView(children: tiles)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
