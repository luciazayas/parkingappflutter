import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helloworldft/externalService/api.dart';
import 'package:latlong2/latlong.dart';
import '/db/database_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<LatLng> routeCoordinates = [];
  final locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
    distanceFilter: 10, // Distance in meters before an update is triggered
  );
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? myLocation;

  @override
  void initState() {
    super.initState();
    myPosition();
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void myPosition() async {
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
        setState(() {
          myLocation = LatLng(position.latitude, position.longitude);
        });
        if (myLocation != null) {
          loadMarkers();
        }
      },
    );
  }

  Future<void> loadMarkers() async {
  List<dynamic> parkings = await fetchParkingMarkers();
  List<Marker> loadedMarkers = parkings.map((parking) {
    return Marker(
      point: LatLng(
          parking["location"]['latitude'], parking["location"]['longitude']),
      width: 80,
      height: 80,
      child: Icon(
        Icons.local_parking,
        size: 60.0,
        color: Colors.blue,
      ),
    );
  }).toList();
  setState(() {
    markers = loadedMarkers;
    if (myLocation != null) {
      markers.add(Marker(
        point: myLocation!,
        width: 80,
        height: 80,
        child: Icon(
          Icons.location_pin,
          size: 60.0,
          color: Colors.red,
        ),
      ));
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map View')),
      body: content(),
    );
  }

  Widget content() {
    return myLocation == null
        ? const Center(
            child: CircularProgressIndicator(), // Indicador de carga
          )
        : FlutterMap(
            options: MapOptions(
              initialCenter: myLocation!,
              initialZoom: 15,
              interactionOptions:
                  InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              openStreetMapTileLayer,
              MarkerLayer(markers: markers),
            ],
          );
  }

  TileLayer get openStreetMapTileLayer => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
      );
}
