import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helloworldft/screens/splash_screen.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '/db/database_helper.dart';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}


class _SecondScreenState extends State<SecondScreen> {
  List<List<String>> _coordinates = [];
  List<List<String>> _dbCoordinates = []; // For coordinates from the database

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
   _loadDbCoordinates();
  }

  Future<void> _loadCoordinates() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    var logger = Logger();
    logger.d(file.toString());
    List<String> lines = await file.readAsLines();
    setState(() {
      _coordinates = lines.map((line) => line.split(';')).toList();
    });
  }

  Future<void> _loadDbCoordinates() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates(); // Corrected
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(), // Corrected
        c['latitude'].toString(), // Corrected
        c['longitude'].toString() // Corrected
      ]).toList();
    });
  }
  void _loadDbCoordinatesAndUpdate() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates();
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(),
        c['latitude'].toString(),
        c['longitude'].toString()
      ]).toList();
    });
  }


  void _showDeleteDialog(String timestamp) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm delete ${timestamp}"),
          content: Text("Do you want to delete this coordinate?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCoordinate(timestamp);
                Navigator.of(context).pop();
                _loadDbCoordinatesAndUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(String timestamp, String currentLat, String currentLong) {
    TextEditingController latController = TextEditingController(text: currentLat);
    TextEditingController longController = TextEditingController(text: currentLong);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update coordinates for ${timestamp}"),
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
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Update"),
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseHelper.instance.updateCoordinate(timestamp, latController.text, longController.text);
                _loadDbCoordinatesAndUpdate();
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
        title: Text('Second Screen'),
      ),
      body: ListView.builder(
        itemCount: _dbCoordinates.length,
        itemBuilder: (context, index) {
          if (index < _dbCoordinates.length) {
            var coord = _dbCoordinates[index];
            var formattedDate = DateFormat('yyyy/MM/dd HH:mm:ss').format(
                DateTime.fromMillisecondsSinceEpoch(int.parse(coord[0])));
            return ListTile(
              title: Text('BD Timestamp: $formattedDate',
                  style: TextStyle(color: Colors.blue)),
              subtitle: Text('Latitude: ${coord[1]}, Longitude: ${coord[2]}',
                  style: TextStyle(color: Colors.blue)),
              onTap: () => _showDeleteDialog(coord[0]),
              onLongPress: () =>
                  _showUpdateDialog(coord[0], coord[1], coord[2]),
            );
          }
        }
      ),
    );
  }




@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This method is called right after initState the first time
    // the widget is built and when any dependencies of the InheritedWidget change.
    print("didChangeDependencies: Dependencies updated.");
  }
  @override
  void didUpdateWidget(SecondScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent widget changes and has to rebuild this widget (because it needs to update the configuration),
    // this method is called with the old widget as an argument.
    print("didUpdateWidget: The widget has been updated from the parent.");
  }
  @override
  void dispose() {
    // This method is called when this state object is permanently removed.
    print("dispose: Cleaning up before the state is destroyed.");
    super.dispose();
  }
}



