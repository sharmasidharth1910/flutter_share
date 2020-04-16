import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String bio;
  final String username;
  final String photoUrl;
  final String email;
  final String displayName;

  User({
    this.id,
    this.displayName,
    this.bio,
    this.email,
    this.photoUrl,
    this.username,
  });

  factory User.fromDocument(DocumentSnapshot doc)
  {
    return User(
      id: doc['id'],
      email: doc['email'],
      displayName: doc['displayName'],
      bio: doc['bio'],
      photoUrl: doc['photoUrl'],
      username: doc['username'],
    );
  }
}
