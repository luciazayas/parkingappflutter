import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helloworldft/screens/second_screen.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fourth_screen.dart';
import 'settings_screen.dart';
import '/db/database_helper.dart';



class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();

  @override
  Widget build(BuildContext context) {
    print('Building SplashScreen');
    var logger = Logger();
    logger.d("Debug message");
    logger.w("Warning message!");
    logger.e("Error message!!");
    return Scaffold(
      appBar: AppBar(
        title: Text('ParkFinder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to ParkFinder',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: ()
              {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FourthScreen()),
                );
              },
              child: const Text('Previous Location'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  DatabaseHelper db = DatabaseHelper.instance;
  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
    distanceFilter: 10, // Distance in meters before an update is triggered
  );
  final logger = Logger();
  final _uidController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    //_loadPrefs();
  }
/*
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? token = prefs.getString('token');
    if (uid == null || token == null) {
      _showInputDialog();
    } else {
      logger.d("UID: $uid, Token: $token");
    }
  }

 */
/*
  Future<void> _showInputDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter UID and Token'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _uidController,
                  decoration: InputDecoration(hintText: "UID"),
                ),
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(hintText: "Token"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('uid', _uidController.text);
                await prefs.setString('token', _tokenController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


 */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ParkFinder'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Activate location'),
            Switch(
              value: _positionStreamSubscription != null,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    startTracking();
                    _positionStreamSubscription = Geolocator.getPositionStream(
                        locationSettings: locationSettings).listen(
                            (Position position)  {
                          _showSnackBar(context,position);
                        });
                  } else {
                    stopTracking();
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecondScreen()),
                );
              },
              child: const Text('Previuos Location'),
            ),
          ],
        ),
      ),
    );
  }


  void startTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position position) {
            writePositionToFile(position);
          },
        );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position position) {
            db.insertCoordinate(position);
          },
        );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> writePositionToFile(Position position) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    String timestamp = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    await file.writeAsString(
        '${timestamp};${position.latitude};${position.longitude}\n',
        mode: FileMode.append);
  }


  void _showSnackBar(BuildContext context, Position position) {
    String timestamp = DateTime
        .now()
        .millisecondsSinceEpoch
        .toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${timestamp};${position.latitude};${position.longitude}'),
        duration: Duration(seconds: 3),
      ),
    );
  }
  @override
  void dispose() {
    _uidController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

}