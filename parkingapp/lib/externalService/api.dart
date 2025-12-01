
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helloworldft/screens/splash_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Parking {
  final String latitud;
  final String longuitud;

  Parking({required this.latitud, required this.longuitud});

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      latitud: json['latitud'],
      longuitud: (json['longuitud']),
    );
  }
}


class ParkingResponse {
  final List<Parking> results;

  ParkingResponse({required this.results});

  factory ParkingResponse.fromJson(Map<String, dynamic> json) {
    var list = json['@graph'] as List;
    List<Parking> parkingList = list.map((i) => Parking.fromJson(i)).toList();
    return ParkingResponse(results: parkingList);
  }
}

Future<List<dynamic>> fetchParkingInfo(var url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var jsonData;
      var body= response.body;
      body=body.replaceAll("--", "-"); // error on the json file
      jsonData = jsonDecode(body);
      if (jsonData['@graph'] != null && jsonData['@graph'] is List) {
        return jsonData['@graph'];
      } else {
        throw Exception('Unexpected JSON format');
      }
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to : $e');
  }
}

Future<List<dynamic>> fetchParking(String latitude,
    String longitude,
    String distancia,) async {
  var fullURL =
      "https://datos.madrid.es/egob/catalogo/202625-0-aparcamientos-publicos.json?latitud=" +
          latitude + "&longitud=" + longitude + "&distancia=" + distancia;
  try {
    final response = await http.get(Uri.parse(fullURL));
    if (response.statusCode == 200) {
      var jsonData;
      var body= response.body;
      body=body.replaceAll("--", "-"); // error on the json file
      jsonData = jsonDecode(body);
      if (jsonData['@graph'] != null && jsonData['@graph'] is List) {
        return jsonData['@graph'];
      } else {
        throw Exception('Unexpected JSON format');
      }
    } else {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to : $e');
  }
}

Future<List<dynamic>>  fetchParkingMarkers() async {
  var baseUrl = "https://datos.madrid.es/egob/catalogo/202625-0-aparcamientos-publicos.json";
  try {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      var jsonData;
      var body= response.body;
      body=body.replaceAll("--", "-"); // error on the json file
      jsonData = jsonDecode(body);
      if (jsonData['@graph'] != null && jsonData['@graph'] is List) {
        return jsonData['@graph'];
      } else {
        throw Exception('Unexpected JSON format');
      }
    }else {
      throw Exception('Failed to load parking data: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load parking data: $e');
  }
}