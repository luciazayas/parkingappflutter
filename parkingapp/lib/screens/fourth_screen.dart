import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helloworldft/screens/splash_screen.dart';
import 'package:helloworldft/screens/third_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../externalService/api.dart';


class FourthScreen extends StatefulWidget {


  @override
  _FourthScreenState createState() => _FourthScreenState();
}

class _FourthScreenState extends State<FourthScreen> {
  late Map<String, dynamic> parking = {};
  late String apiKey = '';
  late String latitude;
  late String longitude;
  late String distancia;
  Future<List<dynamic>>? futureParking;
  StreamSubscription<Position>? _positionStreamSubscription;
  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
    distanceFilter: 10, // Distance in meters before an update is triggered
  );

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> allPrefs = prefs.getKeys().fold<Map<String, dynamic>>(
        {},
            (prev, key) => prev..[key] = prefs.get(key)
    );
    print('All preferences: $allPrefs');
    setState(() {
      apiKey = prefs.getString('token') ?? '';
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _showParameterDialog();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dropdown menu'),
        actions: <Widget>[
          PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'op1',
                  child: Text('Filter by'),
                ),
                const PopupMenuItem<String>(
                  value: 'op2',
                  child: Text('Near'),
                ),
              ],
              onSelected: (String value) {
                switch (value) {
                  case 'op1':
                    _showParameterDialog();
                    break;
                  case 'op2':
                    _nearMe();
                    break;
                }
              }),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: futureParking,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              List<dynamic> parkings = snapshot.data!;
              return ListView.builder(
                itemCount: parkings.length,
                itemBuilder: (context, index) {
                 var url = parkings[index]['@id'];
                  return ListTile(
                    title: Text(parkings[index]['title']),
                      onTap: () =>Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThirdScreen(url:url))),
                  );
                },
              );
            } else {
              return Text('No data found');
            }
          },
        ),

      ),
    );

  }


  Future<void> _nearMe()async {
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
              (Position position) async {
            //futureParking=fetchParking(position.latitude.toString(),position.longitude.toString(),"41000");
                //futureParking=  fetchParking("40.438611","-3.675278","41000");
                var parkingData = await fetchParking(position.latitude.toString(), position.longitude.toString(), "600");
                setState(() {
                futureParking = Future.value(parkingData);
              });
                if(parkingData.isEmpty){
                  print('There are no parking close to your location');
                }
          },
        );

  }

  Future<void> _showParameterDialog() async {
    TextEditingController distanceController = TextEditingController();
    TextEditingController latController = TextEditingController();
    TextEditingController longController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location'),
          content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: latController,
              decoration: InputDecoration(labelText: "Latitude"),
            ),
            TextField(
              controller: longController,
              decoration: InputDecoration(labelText: "Longitude"),
            ),
            TextField(
              controller: distanceController,
              decoration: InputDecoration(labelText: "Distance"),
            ),
          ],
        ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                setState(() {
                  distancia = distanceController.text;
                  longitude= longController.text;
                  latitude= latController.text;
                  futureParking = fetchParking(latitude,longitude,distancia);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

}
