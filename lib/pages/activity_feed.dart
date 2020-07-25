import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialapp/pages/post_screen.dart';
import 'package:socialapp/pages/profile.dart';
import 'package:socialapp/widgets/header.dart';
import 'package:socialapp/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'home.dart';

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: false, titleText: 'Activity Feed'),
      body: Container(
        child: FutureBuilder(
          future: getActivityFeed(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            return ListView(
              children: snapshot.data,
            );
          },
        ),
      ),
    );
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  const ActivityFeedItem(
      {this.username,
      this.userId,
      this.type,
      this.mediaUrl,
      this.postId,
      this.userProfileImg,
      this.commentData,
      this.timestamp});

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
    );
  }
  configureMediaPreview(context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () => showPost(context),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: mediaUrl != null
                      ? CachedNetworkImageProvider(mediaUrl)
                      : AssetImage("assets/images/google_signin_button.png"),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }
    if (type == 'like') {
      activityItemText = "  liked your post";
    } else if (type == 'follow') {
      activityItemText = "  is following you";
    } else if (type == 'comment') {
      activityItemText = 'replied:  $commentData';
    } else {
      activityItemText = "Error: Unknown type  '$type'";
    }
  }

  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostScreen(
            postId: '$postId',
            userId: '$userId',
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown[50],
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor),
                  ),
                  TextSpan(
                    text: '$activityItemText',
                  ),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: userProfileImg != null
                ? CachedNetworkImageProvider(userProfileImg)
                : AssetImage('assets/images/google_signin_button.png'),
          ),
          subtitle: Text(
            timeAgo.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}
