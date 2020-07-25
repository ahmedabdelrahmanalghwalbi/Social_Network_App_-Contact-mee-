import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialapp/pages/activity_feed.dart';
import 'package:socialapp/models/user.dart';
import 'package:socialapp/widgets/progress.dart';
import 'home.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
   Future<QuerySnapshot> searchResultFuture;
   clearSearch(){
     searchController.clear();
   }
   handleSearch(query){
   Future<QuerySnapshot> users=userRef.where('displayName',isGreaterThanOrEqualTo: query).getDocuments();
   setState(() {
     searchResultFuture=users;
   });
  }
  buildSearchResult(){
  return FutureBuilder(
    future:searchResultFuture,
    builder: (context,snapshot){
      if(!snapshot.hasData){
        return circularProgress();
      }
      List<UserResult> searchResults=[];
      snapshot.data.documents.forEach((doc){
        User user=User.fromDocument(doc);
        UserResult searchResult=UserResult(user);
        searchResults.add(searchResult);
      });
      return ListView(
        children: searchResults,
      );
    },
  );

  }

  AppBar buildSearchField(){
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search ...",
          hintStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          filled: true,
          prefixIcon: Icon(
            Icons.search,
            size: 28,
            color: Theme.of(context).accentColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed:clearSearch,
          ),
        ),
        onFieldSubmitted:handleSearch,
      ),
    );
  }
  buildNoContent(){
    final Orientation orientation =MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset('assets/images/search.svg',height:orientation==Orientation.portrait?300:200,),
            Center(
              child: Text("Find Users",style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
                fontSize: 55,
              ),),
            ),
          ],
        ),
      ),
    );
  }
  bool get wantKeepAlive =>true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
   appBar: buildSearchField(),
      body: searchResultFuture ==null?buildNoContent():buildSearchResult(),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(.8),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(.7),
      child: Column(children: <Widget>[
        GestureDetector(
          onTap: ()=>showProfile(context,profileId: user.id),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            ),
            title: Text('${user.dispalyName}',style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
            ),),
            subtitle: Text('${user.username}',style: TextStyle(
              color: Colors.white,
            ),),
          ),
        ),
        Divider(
          height: 2.0,
          color: Colors.white54,
        )
      ],),
    );
  }
}
