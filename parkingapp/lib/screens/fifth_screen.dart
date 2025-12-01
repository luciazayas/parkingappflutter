import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:helloworldft/externalService/api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:helloworldft/screens/fifth_screen.dart';

class FifthScreen extends StatefulWidget {
  final String id;

  FifthScreen({required this.id});

  @override
  _FifthScreenState createState() => _FifthScreenState();
}

class _FifthScreenState extends State<FifthScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int starts = 0;

  Widget _buildRatingStar(int index) {
    User? user = _auth.currentUser;
    return GestureDetector(
      onTap: () {
        setState(() {
          starts = index;
        });
        //_submitFeedback(context, user);
      },
      child: Icon(
        Icons.star,
        color: starts >= index ? Colors.amber : Colors.grey,
        size: 36.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Comment'),
            ),
            SizedBox(height: 16.0),
            Text('Rating:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (int i = 1; i <= 5; i++) _buildRatingStar(i),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _submitFeedback(context, user),
              child: Text('Submit Feedback'),
            ),
            SizedBox(height: 16.0),
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref().child('feedback').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  List<Widget> commentWidgets = [];
                  Map<dynamic, dynamic>? data =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                  if (data != null ) {
                    data.forEach((key, value) {
                      if(value['parking'] == widget.id) {
                        commentWidgets.add(
                          LongPressDraggable(
                            data: key,
                            feedback: ListTile(
                              title: Text(value['comment']),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _showUpdateDialog(
                                  context,
                                  key,
                                  value['comment'],
                                  value['rating'],
                                );
                              },
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Delete Feedback'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Timestamp: ${DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                  value['timestamp'])}'),
                                          Text('Comment: ${value['comment']}'),
                                          Text('Rating: ${value['rating']}'),
                                          SizedBox(height: 16),
                                          Text(
                                              'Are you sure you want to delete this feedback?'),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            DatabaseReference feedbackRef =
                                            FirebaseDatabase.instance
                                                .reference()
                                                .child('feedback').child(key);
                                            feedbackRef.remove().then((_) {
                                              Fluttertoast.showToast(
                                                msg:
                                                "Feedback deleted successfully.",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                              );
                                              Navigator.of(context).pop();
                                            }).catchError((error) {
                                              print(
                                                  "Failed to delete feedback: $error");
                                              Fluttertoast.showToast(
                                                msg: "Failed to delete feedback.",
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.BOTTOM,
                                              );
                                            });
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: ListTile(
                                title: Text(value['comment']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Rating: ${value['rating']}'),
                                    Text(user!.email.toString()),
                                  ],
                                ),
                                leading: Text(
                                    '${DateTime.fromMillisecondsSinceEpoch(
                                        value['timestamp'])}'),
                              ),
                            ),
                          ),
                        );
                      }
                    });
                  }
                  return Expanded(
                    child: ListView(
                      children: commentWidgets,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, String key,
      String currentComment, int currentRating) {
    TextEditingController commentController =
        TextEditingController(text: currentComment);
    int rating = currentRating;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: "Comment"),
              ),
              SizedBox(height: 16.0),
              Text('rating:'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  for (int i = 1; i <= 5; i++) _buildRatingStar(i),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update feedback in database
                DatabaseReference feedbackRef = FirebaseDatabase.instance
                    .ref()
                    .child('feedback')
                    .child(key);
                feedbackRef.update({
                  'comment': commentController.text,
                  'rating': rating,
                }).then((_) {
                  Fluttertoast.showToast(
                    msg: "Feedback updated successfully.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  Navigator.of(context).pop();
                }).catchError((error) {
                  print("Failed to update feedback: $error");
                  Fluttertoast.showToast(
                    msg: "Failed to update feedback.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                });
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _submitFeedback(BuildContext context, User? user) {
    String comment = _commentController.text;
    if (comment.isEmpty || starts == 0) {
      Fluttertoast.showToast(
        msg: "Please fill all fields.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    DatabaseReference feedbackRef =
        FirebaseDatabase.instance.ref().child('feedback');
    feedbackRef.push().set({
      'uid': user?.uid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'comment': comment,
      'rating': starts,
      'parking': widget.id,
    }).then((value) {
      Fluttertoast.showToast(
        msg: "Feedback submitted successfully.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }).catchError((error) {
      print("Failed to submit feedback: $error");
      Fluttertoast.showToast(
        msg: "Failed to submit feedback.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    });
  }
}
