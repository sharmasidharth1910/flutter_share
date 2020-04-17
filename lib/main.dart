import 'package:flutter/material.dart';
import 'package:flutter_share/pages/home.dart';

void main()
{
  // Firestore.instance.settings(timestampsInSnapshotsEnabled : true).then((_){
  //   print("Timestamps enabled in snapshots\n");
  // });
   runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterShare',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
