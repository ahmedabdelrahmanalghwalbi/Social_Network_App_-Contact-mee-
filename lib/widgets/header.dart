import 'package:flutter/material.dart';

AppBar header(context,{bool isAppTitle =true , String titleText,removeBackButton=false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton?false:true,
    title: Text(
      isAppTitle?'Contact Mee':titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: "signatra",
        fontSize:isAppTitle? 50:30,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
