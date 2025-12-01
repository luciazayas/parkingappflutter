import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:helloworldft/externalService/api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:helloworldft/screens/fifth_screen.dart';



class ThirdScreen extends StatefulWidget {
  final String url;

  ThirdScreen({required this.url});

  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}
class _ThirdScreenState extends State<ThirdScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;


  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () => {},
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Get link'),
              onTap: () => {},
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
        title: Text('Third screen'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => _showModalBottomSheet(context),
            child: Text('More Option'),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<dynamic>>(
          future: fetchParkingInfo(widget.url),
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
                  var id= parkings[index]['title'];
                  return ListTile(
                    title: Text(parkings[index]['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dirección Calle: ${parkings[index]['address']['street-address']}'),
                        Text('Dirección Locality: ${parkings[index]['address']['locality']}'),
                        Text('Codigo Postal: ${parkings[index]['address']['postal-code']}'),
                        Text('Informacion: ${parkings[index]['organization']['organization-desc']}'),
                        Text('Latitud: ${parkings[index]['location']['latitude']}'),
                        Text('Longuitud: ${parkings[index]['location']['longitude']}'),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FifthScreen(id:id)));
                          },
                          child: Text('Feedback'),
                        ),
                      ],
                    ),
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
}
