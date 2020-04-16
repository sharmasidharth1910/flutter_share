import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_share/models/user.dart';
import 'package:flutter_share/pages/search.dart';
import 'package:flutter_share/widgets/header.dart';
import 'package:flutter_share/pages/home.dart';
import 'package:flutter_share/widgets/post.dart';
import 'package:flutter_share/widgets/progress.dart';

final usersRef = Firestore.instance.collection("users");

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({
    this.currentUser,
  });

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> _posts = [];
  List<String> _followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection("userFollowing")
        .getDocuments();
    setState(() {
      _followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection("timelinePosts")
        .orderBy("timestamp", descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      _posts = posts;
    });
  }

  buildUsersToFollow() {
    return StreamBuilder(
        stream: usersRef
            .orderBy('timestamp', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> userResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            final bool isAuthUser = currentUser.id == user.id;
            final bool isFollowingUser = _followingList.contains(user.id);
            //remove that user from the recommendation list
            if (isAuthUser) {
              return;
            } else if (isFollowingUser) {
              return;
            }
            else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          });
        });
  }

  buildTimeline() {
    if (_posts == null) {
      return circularProgress();
    } else if (_posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(
        children: _posts,
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
