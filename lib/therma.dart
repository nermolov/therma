import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class ThermaPage extends StatefulWidget {
  ThermaPage({Key key, this.address}) : super(key: key);

  // TODO: change from [String]
  final String address;

  @override
  _ThermaPageState createState() => new _ThermaPageState();
}

enum ThermState { heat, cool, off }
enum FanState { on, auto }

class _ThermaPageState extends State<ThermaPage> {
  ThermState _thermState;
  FanState _fanState;
  double _heatTarget;
  double _coolTarget;
  double _curTemp;

  Timer _updWait;
  BuildContext _scontext;

  @override
  void initState() {
//    this._curTemp = 65;
//    this._thermState = ThermState.off;
//    this._fanState = FanState.auto;
//    this._heatTarget = 68;
//    this._coolTarget = 78;
    _loadState();
    super.initState();
  }

  void _loadState() async {
    Map<String, dynamic> res = json.decode((await http.get('http://' + widget.address + '/tstat')).body);
    setState(() {
      this._curTemp = res['temp'];
      switch (res['tmode']) {
        case 0:
          this._thermState = ThermState.off;
          break;
        case 1:
          this._thermState = ThermState.heat;
          break;
        case 2:
          this._thermState = ThermState.cool;
          break;
      }
      switch (res['fmode']) {
        case 2:
          this._fanState = FanState.on;
          break;
        case 0:
          this._fanState = FanState.auto;
          break;
      }
      this._heatTarget = res['t_heat'];
      this._coolTarget = res['t_cool'];
    });
  }

  void _updateState() {
    if (this._updWait != null) this._updWait.cancel();
    this._updWait = new Timer(new Duration(seconds: 2), _messageState);
  }

  void _messageState() async {
    Map<String, dynamic> sdata = {'fmode': this._fanState == FanState.on ? 2 : 0};
    switch (this._thermState) {
      case ThermState.heat:
        sdata['tmode'] = 1;
        sdata['t_heat'] = this._heatTarget;
        break;
      case ThermState.cool:
        sdata['tmode'] = 2;
        sdata['t_cool'] = this._coolTarget;
        break;
      case ThermState.off:
        sdata['tmode'] = 0;
        break;
    }
    Scaffold.of(this._scontext)
        .showSnackBar(new SnackBar(content: new Text('Updating...'), duration: Duration(seconds: 1)));
    try {
      await http.post('http://' + widget.address + '/tstat', body: json.encode(sdata));
      // TODO: check for success: 0
      Scaffold.of(this._scontext)
          .showSnackBar(new SnackBar(content: new Text('Updated!'), duration: Duration(seconds: 1)));
    } catch (e) {
      print(e);
      Scaffold.of(this._scontext)
          .showSnackBar(new SnackBar(content: new Text('An error has occured')));
    }
  }

  void _setThermState(nstate) {
    setState(() {
      this._thermState = nstate;
    });
    _updateState();
  }
  void _setFanState(nstate) {
    setState(() {
      this._fanState = nstate;
    });
    _updateState();
  }

  void _increaseTemp() {
    setState(() {
      if (this._thermState == ThermState.heat) {
        this._heatTarget += 1;
      } else if (this._thermState == ThermState.cool) {
        this._coolTarget += 1;
      }
    });
    _updateState();
  }
  void _decreaseTemp() {
    setState(() {
      if (this._thermState == ThermState.heat) {
        this._heatTarget -= 1;
      } else if (this._thermState == ThermState.cool) {
        this._coolTarget -= 1;
      }
    });
    _updateState();
  }

  double _getTarget() {
    if (this._thermState == ThermState.heat) return this._heatTarget;
    if (this._thermState == ThermState.cool) return this._coolTarget;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.address),
        ),
        body: Builder(builder: (BuildContext context) {
          this._scontext = context;
          return new Padding(
            padding: const EdgeInsets.all(16.0),
            child: new Column(
              children: <Widget>[
                new Row(children: <Widget>[
                  new Expanded(
                      flex: 7,
                      child: new FittedBox(
                        fit: BoxFit.contain,
                        child: new Text(
                          this._curTemp == null
                                    ? '00°'
                                    : this._curTemp.toString() + '°',
                          style: new TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                  new Expanded(
                      flex: 3,
                      child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new FittedBox(
                                child: new IconButton(
                              icon: Icon(Icons.expand_less),
                              onPressed: this._thermState == ThermState.off ? null : _increaseTemp,
                            )),
                            new FittedBox(
                              child: new Text(
                                _getTarget() == null
                                    ? '00°'
                                    : _getTarget().truncate().toString() + '°',
                                style: new TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            new FittedBox(
                                child: new IconButton(
                              icon: Icon(Icons.expand_more),
                              onPressed: this._thermState == ThermState.off ? null : _decreaseTemp,
                            )),
                          ]))
                ]),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new RaisedButton.icon(
                        color: this._thermState == ThermState.heat
                            ? Colors.red
                            : Theme.of(context).buttonColor,
                        textColor: this._thermState == ThermState.heat
                            ? Colors.white
                            : Colors.black,
                        icon: new Icon(Icons.whatshot),
                        label: new Text('HEAT'),
                        onPressed: this._thermState == null ? null : () => _setThermState(ThermState.heat)),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: new RaisedButton.icon(
                          color: this._thermState == ThermState.cool
                              ? Colors.blue
                              : Theme.of(context).buttonColor,
                          textColor: this._thermState == ThermState.cool
                              ? Colors.white
                              : Colors.black,
                          icon: new Icon(Icons.ac_unit),
                          label: new Text('COOL'),
                          onPressed: this._thermState == null ? null : () => _setThermState(ThermState.cool)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: new RaisedButton.icon(
                          color: this._thermState == ThermState.off
                              ? Colors.blueGrey
                              : Theme.of(context).buttonColor,
                          textColor: this._thermState == ThermState.off
                              ? Colors.white
                              : Colors.black,
                          icon: new Icon(Icons.close),
                          label: new Text('OFF'),
                          onPressed: this._thermState == null ? null : () => _setThermState(ThermState.off)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new RaisedButton.icon(
                          color: this._fanState == FanState.on
                              ? Colors.orange[200]
                              : Theme.of(context).buttonColor,
                          icon: new Icon(Icons.toys),
                          label: new Text('FAN ON'),
                          onPressed: this._thermState == null ? null : () => _setFanState(FanState.on)),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: new RaisedButton.icon(
                            color: this._fanState == FanState.auto
                                ? Colors.orange[200]
                                : Theme.of(context).buttonColor,
                            icon: new Icon(Icons.track_changes),
                            label: new Text('FAN AUTO'),
                            onPressed: this._thermState == null ? null : () => _setFanState(FanState.auto)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        }));
  }
}
