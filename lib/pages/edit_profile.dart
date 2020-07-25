import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:socialapp/models/user.dart';
import 'package:socialapp/pages/home.dart';
import 'package:socialapp/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey=GlobalKey<ScaffoldState>();
  TextEditingController displayNameController=TextEditingController();
  TextEditingController bioController =TextEditingController();
  bool isLoading =false;
  User user;
  bool _bioValid=true;
  bool _displayNameValid=true;
  @override
  void initState() {
    getUser();
    super.initState();
  }
  getUser()async{
    setState(() {
      isLoading=true;
    });
    DocumentSnapshot doc=await userRef.document(widget.currentUserId).get();
   user = User.fromDocument(doc);
   displayNameController.text=user.dispalyName;
   bioController.text=user.bio;
   setState(() {
     isLoading=false;
   });
  }

  Column buildDisplayNameField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 30),
          child: Text("Display Name",style: TextStyle(
            color:Theme.of(context).accentColor,
            fontSize: 20
          ),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "update Display Name",
            errorText: _displayNameValid?null:"Display Name too short",
          ),
        ),
      ],
    );
  }

  Column buildBioField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 30),
          child: Text("Bio",style: TextStyle(
              color: Theme.of(context).accentColor,
            fontSize: 20
          ),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "update Bio",
            errorText: _bioValid?null:"Bio is too long",
          ),
        ),
      ],
    );
  }
  updateProfileData(){
    setState(() {
      displayNameController.text.trim().length < 3 || displayNameController.text.isEmpty?
          _displayNameValid=false:_displayNameValid=true;
      bioController.text.trim().length >100?_bioValid =false:_bioValid =true;
    });
    if(_displayNameValid && _bioValid){
      userRef.document(widget.currentUserId).updateData({
        "displayName":displayNameController.text,
        "bio":bioController.text,
      });
      SnackBar snackBar =SnackBar(
        content: Text("Profile Updated"),
      );
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }
  logout()async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(
      builder: (context)=>Home(),
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          "edit profile",
          style: TextStyle(
            fontSize: 40,
            color: Colors.black,
            fontFamily: "signatra",
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: ()=>Navigator.pop(context),
            icon: Icon(
              Icons.done,
              size: 30,
              color: Colors.green,
            ),
          ),
        ],
      ),
      body: isLoading?circularProgress():ListView(
        children: <Widget>[
            Container(
              padding: EdgeInsets.all(15),
              width:100 ,
              height: 400,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                buildDisplayNameField(),
                buildBioField(),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Center(
            child: Container(
              width: 200,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor,width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: GestureDetector(
                onTap: updateProfileData,
                child: Center(
                  child: Text(
                    "update Profile",
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: FlatButton.icon(onPressed: logout, icon:Icon(Icons.cancel,color: Colors.red,), label:Text(
              "Logout",
              style: TextStyle(
                color: Colors.red,
                fontSize: 25
              ),
            )),
          ),
        ],
      ),
    );
  }
}
