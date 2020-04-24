import "package:flutter/material.dart";
import 'package:flutter/cupertino.dart';

Future<void> showValidationMessage({BuildContext context, String title}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true, // user must tap button!
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(title, style: TextStyle(fontFamily: 'BalooChettan2')),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(fontFamily: 'BalooChettan2')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

const textInputDecoration = InputDecoration(
    labelStyle: TextStyle(color: Colors.black, fontFamily: 'BalooChettan2'),
    hintStyle: TextStyle(fontFamily: 'BalooChettan2'),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(15.0))
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(15.0))
    ),
    filled: true
  );
