import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:socialapp/models/user.dart';
import 'package:socialapp/pages/edit_profile.dart';
import 'package:socialapp/pages/home.dart';
import 'package:socialapp/widgets/header.dart';
import 'package:socialapp/widgets/post.dart';
import 'package:socialapp/widgets/post_tile.dart';
import 'package:socialapp/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  int followerCount=0;
  int followingCount=0;
  int postCount = 0;
  List<Post> posts = [];
  String postOrientation = "grid";
  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing()async{
    DocumentSnapshot doc = await followersRef.document(widget.profileId).collection('userFollowers')
        .document(currentUserId).get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers()async{
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length ;
    });
  }

  getFollowing()async{
    QuerySnapshot snapshot =await followingRef.document(widget.profileId).collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount=snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.formDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String lable, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '${count.toString()}',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Theme.of(context).primaryColor),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            '$lable',
            style: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfile(currentUserId: currentUserId),
        ));
  }

  buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: MediaQuery.of(context).size.width*0.5,
          height: 40,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 25,
              color:isFollowing?Theme.of(context).primaryColor:Colors.white,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing?Colors.white:Colors.blue,
            border: Border.all(
              color: isFollowing?Theme.of(context).accentColor:Colors.blue,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    //viewing your own Profile - should show edit profile button
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: "Edit Profile",
        function: editProfile,
      );
    }else if(isFollowing){
      return buildButton(text: "unfollow",
          function: handleUnFollowUser,
      );
    }else if(!isFollowing){
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  handleUnFollowUser(){
    setState(() {
      isFollowing=false;
    });
    followersRef.document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId).get().then((doc) {
       if(doc.exists){
         doc.reference.delete();
       }
    });
    followingRef.document(currentUserId)
        .collection("userFollowing").document(widget.profileId)
        .get().then((doc) {
      if(doc.exists){
        doc.reference.delete();
      }
    }
    );

    activityFeedRef.document(widget.profileId)
        .collection('feedItems').document(currentUserId)..get().then((doc) {
      if(doc.exists){
        doc.reference.delete();
      }
    }
    );
  }

  handleFollowUser(){
  setState(() {
    isFollowing=true;
  });
  followersRef.document(widget.profileId).collection("userFollowers").document(currentUserId).setData({
    "type":"follow",
    "ownerId":widget.profileId,
    "username":currentUser.username,
    "userId":currentUserId,
    "userProfileImg":currentUser.photoUrl,
    "timestamp":timestamp,
  });
  followingRef.document(currentUserId).collection("userFollowing").document(widget.profileId).setData({
    "type":"follow",
    "ownerId":widget.profileId,
    "username":currentUser.username,
    "userId":currentUserId,
    "userProfileImg":currentUser.photoUrl,
    "timestamp":timestamp,
  });
  activityFeedRef.document(widget.profileId).collection('feedItems').document(currentUserId).setData({
    "type":"follow",
    "ownerId":widget.profileId,
    "username":currentUser.username,
    "userId":currentUserId,
    "userProfileImg":currentUser.photoUrl,
    "timestamp":timestamp,
  });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followerCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12,bottom: 5),
                child: Text(
                  '${user.username}',
                  style: TextStyle(fontSize: 25,color: Theme.of(context).accentColor),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0,bottom: 5),
                child: Text(
                  '${user.dispalyName}',
                  style: TextStyle(
                      color:Theme.of(context).accentColor,
                    fontSize: 17,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${user.bio}',style: TextStyle(
                  color:Theme.of(context).accentColor,
                  fontSize: 17,
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              "assets/images/no_content.svg",
              height: 260,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                "No Posts",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setPostOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: false, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
