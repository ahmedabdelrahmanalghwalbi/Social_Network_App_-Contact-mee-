import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:socialapp/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:socialapp/pages/activity_feed.dart';
import 'package:socialapp/pages/profile.dart';
import 'package:socialapp/pages/search.dart';
import 'package:socialapp/pages/upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_account.dart';
import 'timeline.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:socialapp/widgets/navbar.dart';

final userRef = Firestore.instance.collection('users');
final postRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');

final StorageReference storageRef = FirebaseStorage.instance.ref();
final GoogleSignIn googleSignIn = GoogleSignIn();
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  int pageIndex = 0;
  PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    //detected when users signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('error in sign in $err');
    });
    //Re-authenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('error in sign in $err');
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      await configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getIosPermission();
    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      userRef.document(user.id).updateData({"androidNotificationToken": token});
    });
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackBar = SnackBar(
            content: Text(
              body,
              overflow: TextOverflow.ellipsis,
            ),
          );
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
        print("Notification Not shown!");
      },
    );
  }

  getIosPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  ontap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  createUserInFireStore() async {
    //1)check if user exists in user collection in database (according to id).
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();
    //2)if the user doesn't exist,then we want to take them to the create account page
    if (!doc.exists) {
      final username =
          await Navigator.push(context, MaterialPageRoute(builder: (context) {
        return CreateAccount();
      }));

      //3)get username from create account ,use it to make new user document in users collection
      userRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "dispalyName": user.displayName,
        "bio": "",
        "timestamp": timestamp,
      });
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});
      doc = await userRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
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
        onTap: ontap,
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
              size: 35,
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

  Widget buildunAuthScreen() {
    return Scaffold(
      body:_getNavbar(this.context),
    );
  }

  _getNavbar(context){
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).accentColor,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 30,left: 25),
                  child: Text(
                    'Contact Mee',
                    style: TextStyle(
                      fontFamily: "Signatra",
                      fontSize: 90,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Text(
                    'Welcome!',
                    style: TextStyle(
                      fontFamily: "Signatra",
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius:BorderRadius.circular(25),
                      color: Colors.white
                  ),
                  width:MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height*.5,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text('SignIn or LogIn with G-mail.',style: TextStyle(
                          fontFamily: 'Signatra',
                          fontSize: 40,
                          color: Theme.of(context).primaryColor,
                        ),),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30,right: 30),
                        child: Divider(
                          height: 40,
                          thickness: 2,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Center(
                        child: Container(
                          width: 250,
                          height: 70,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).primaryColor,width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: GestureDetector(
                            onTap: login,
                            child: Center(
                              child: Text('Lets Go..!',style: TextStyle(
                                fontFamily: 'Signatra',
                                fontSize: 40,
                                color: Theme.of(context).primaryColor,
                              ),),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: ClipPath(
              clipper: NavBarClipper(),
              child: new Container(
                height: 60,
                width: MediaQuery.of(context).size.width,
                decoration: new BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).accentColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text('Contact',style: new TextStyle(color: Colors.white.withOpacity(0.9),fontWeight: FontWeight.w500),),
                SizedBox(width: 1),
                Text('Friends',style: new TextStyle(color: Colors.white.withOpacity(0.9),fontWeight: FontWeight.w500),),
                SizedBox(width: 1),
                Text('Now..!',style: new TextStyle(color: Colors.white.withOpacity(0.9),fontWeight: FontWeight.w500),),
              ],
            ),
          ),
          Positioned(
            bottom: 45,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildNavItem(Icons.phone, false),
                SizedBox(width: 1),
                _buildNavItem(Icons.people_outline, true),
                SizedBox(width: 1),
                _buildNavItem(Icons.flash_on, false),
              ],
            ),
          ),
        ],
      ),
    );
  }
  _buildNavItem(IconData icon,bool active){
    return CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).primaryColor,
      child: new CircleAvatar(
        radius: 25,
        backgroundColor: active?Colors.white.withOpacity(0.9):Colors.transparent,
        child: Icon(icon,color: active?Colors.black:Colors.white.withOpacity(0.9),),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildunAuthScreen();
  }
}
