import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/activity_feed.dart';
import 'package:flutter_share/pages/create_account.dart';
import 'package:flutter_share/pages/profile.dart';
import 'package:flutter_share/pages/search.dart';
import 'package:flutter_share/pages/timeline.dart';
import 'package:flutter_share/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final DateTime timeStamp = DateTime.now();
final followersRef = Firestore.instance.collection("followers");
final followingRef = Firestore.instance.collection("following");
final activityFeedRef = Firestore.instance.collection("feed");
final postsRef = Firestore.instance.collection("posts");
final timelineRef = Firestore.instance.collection("timeline");
final commentsRef = Firestore.instance.collection("comments");
final usersRef = Firestore.instance.collection("users");
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    //This detects when user signed in or signed out initially during the build time
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (error) {
      print("Error signing in: $error");
    });
    //Re-authenticate the user when application is opened again
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((error) {
      print("Error signing in: $error");
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print("Firebase messaging token: $token\n");
      usersRef.document(user.id).updateData({
        "androidNotificationToken": token,
      });
    });

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("Message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown");
          SnackBar snackBar = SnackBar(
              content: Text(
                body,
                overflow: TextOverflow.ellipsis,
              ));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
        print("Notification not received");
      },
    );
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      alert: true,
      sound: true,
      badge: true,
    ));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  createUserInFirestore() async {
    // 1)check if user exists in users collection in database (according to the user id)
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();

    // 2)If the user doesn't exist, then we want to take them to the create account page
    if (!doc.exists) {
      final username = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateAccount()),
      );
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timeStamp": timeStamp,
      });
      //make the new user their own follower to include their post in timeline
      await followersRef
          .document(user.id)
          .collection("userFollowers")
          .document(user.id)
          .setData({});
      doc = await usersRef.document(user.id).get();
    }

    // 3)Get username from create account, use it to make new user document in users collection
    currentUser = User.fromDocument(doc);
  }

  void login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      curve: Curves.easeIn,
      duration: Duration(milliseconds: 300),
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
  }

  Widget buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Theme.of(context).primaryColor.withRed(100),
            Theme.of(context).accentColor.withOpacity(0.8),
          ], begin: Alignment.topRight, end: Alignment.bottomLeft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Flutter Share",
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage("assets/images/google_signin_button.png"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
