import 'package:flutter/material.dart';
import 'package:socialapp/pages/home.dart';
import 'package:socialapp/pages/search.dart';
import 'package:socialapp/widgets/header.dart';
import 'package:socialapp/widgets/progress.dart';
import 'package:socialapp/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialapp/widgets/post.dart';


final userRef=Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({ this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList=[];
  @override
  void initState(){
    super.initState();
    getTimeLine();
    getFollowing();
  }
  getTimeLine()async{
    QuerySnapshot snapshot = await timelineRef.document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp',descending: true)
        .getDocuments();
    List<Post> posts=snapshot.documents.map((doc) => Post.formDocument(doc)).toList();
    setState(() {
      this.posts=posts;
    });
  }

  getFollowing()async{
    QuerySnapshot snapshot = await followingRef.document(currentUser.id).collection('userFollowing').getDocuments();
    setState(() {
      followingList=snapshot.documents.map((doc) =>doc.documentID ).toList();
    });
  }

  buildTimeLine() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else {
      return ListView(children: posts,);
    }
  }

  buildUsersToFollow(){
    return StreamBuilder(
      stream: userRef.orderBy('timestamp',descending: true).limit(30).snapshots(),
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc){
          User user =User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser=followingList.contains(user.id);
          if(isAuthUser){
            return;
          }else if(isFollowingUser){
            return;
          }else{
            UserResult userResult =UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size:30,
                    ),
                    SizedBox(width: 8,),
                    Text(
                      "Follow Friends Now ..!",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: userResults,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget build(context) {
    return Scaffold(
      appBar: header(context),
     body: RefreshIndicator(
       onRefresh: ()=>getTimeLine(),
       child: buildTimeLine(),
     ),
    );
  }
}
