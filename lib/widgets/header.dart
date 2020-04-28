import 'package:flutter/material.dart';

AppBar header(BuildContext context,
    {bool isAppTitle = false,
      String titleText,
      removeBackButton = false,
      Function onPressed,
      bool chat = false}) {
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text(
      isAppTitle ? "FlutterShare" : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? "Signatra" : "",
        fontSize: isAppTitle ? 50.0 : 22.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: isAppTitle,
    backgroundColor: Theme.of(context).accentColor,
    actions: <Widget>[
      chat
          ? IconButton(
        icon: Icon(Icons.fast_forward),
        iconSize: 30.0,
        onPressed: onPressed,
        tooltip: "Chat",
      )
          : Text(""),
    ],
  );
}
