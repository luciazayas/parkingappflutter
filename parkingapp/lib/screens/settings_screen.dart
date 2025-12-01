import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/login_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, TextEditingController> controllers = {};

  Future<Map<String, dynamic>> _fetchAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> prefsMap = {};
    for (String key in keys) {
      if (key != 'password') { // Exclude password
        prefsMap[key] = prefs.get(key);
        controllers[key] = TextEditingController(text: prefs.get(key).toString());
      }
    }
    return prefsMap;
  }

  Future<void> _updatePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        actions: <Widget>[
          IconButton(
            icon: Icon(FontAwesomeIcons.signOut, size: 30.0, color: Colors.blue),
            onPressed: () {
              _showLogoutConfirmationDialog();
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAllPreferences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    children: snapshot.data!.entries.map((entry) {
                      if (entry.key == 'email' || entry.key == 'uid' || entry.key == 'Token') {
                        return ListTile(
                          title: Text("${entry.key}"),
                          subtitle: Text("${entry.value}"),
                        );
                      } else {
                        return ListTile(
                          title: Text("${entry.key}"),
                          subtitle: TextField(
                            controller: controllers[entry.key],
                            decoration: InputDecoration(hintText: "Enter ${entry.key}"),
                            onSubmitted: (value) {
                              _updatePreference(entry.key, value);
                            },
                          ),
                        );
                      }
                    }).toList(),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Función para mostrar el diálogo de confirmación de logout
  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                _signOut(); // Realiza el logout
              },
            ),
          ],
        );
      },
    );
  }

  // Función para hacer logout
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut(); // Hace logout
    // Redirige a la pantalla de login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
