import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String dispalyName;
  final String bio;

  User(
      {this.id,
      this.username,
      this.email,
      this.photoUrl,
      this.dispalyName,
      this.bio});

  factory User.fromDocument(DocumentSnapshot doc){
    return User(
      id:doc['id'],
      username: doc['username'],
      email: doc['email'],
      photoUrl: doc['photoUrl'],
      dispalyName: doc['displayName'],
      bio: doc['bio'],
    );
  }
}
