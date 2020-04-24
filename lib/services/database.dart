import "package:cloud_firestore/cloud_firestore.dart";
import 'package:notice_board/noticePost.dart';
import 'package:flutter/material.dart';

class DatabaseService{

  final TargetPlatform platform;
  DatabaseService({this.platform});

  final CollectionReference noticePostsRef = Firestore.instance.collection('noticePosts');

  //Note query needs to be modified based on the branch of the user
  Stream<List<Notice>> get noticeStream{
    return noticePostsRef
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.documents
      .map((document) => Notice.fromDocument(document, platform))
      .toList());
  }

}