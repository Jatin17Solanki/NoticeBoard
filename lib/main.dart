import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notice_board/services/database.dart';
import 'package:provider/provider.dart';
import 'noticePost.dart';
import 'package:notice_board/screens/upload_notice.dart';

import 'package:flutter_downloader/flutter_downloader.dart'; //step 1

void main() async {

  WidgetsFlutterBinding.ensureInitialized();  //step 2
  await FlutterDownloader.initialize(); //step 2

  runApp(MyApp());
}

final CollectionReference noticePostsRef = Firestore.instance.collection('noticePosts');

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {

    final platform = Theme.of(context).platform;  //step 3

    return StreamProvider<List<Notice>>.value(
        value: DatabaseService(platform: platform).noticeStream,
        child: MaterialApp( 
        debugShowCheckedModeBanner: false,
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //For the floating action button- scroll action
  ScrollController _scrollController = ScrollController();
  scrollToTop() {
    _scrollController.animateTo(_scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 500), curve: Curves.easeIn);
    setState(() {});
  }

  buildNoticeFeed() {

    var noticeList = Provider.of<List<Notice>>(context) ?? [];
    
    if( noticeList.isEmpty || noticeList == null) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              color: Colors.white,
              child: Center(
                child: Text('No notices for you!',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'BalooChettan2',
                    fontWeight: FontWeight.w700,
                    fontSize: 35.0
                  )
                ),
              ),
            ),
        ),
      );
    }
    return ListView(
      controller: _scrollController,
      children: noticeList,
    );
    
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
        appBar: AppBar(
          // backgroundColor: Colors.grey[800],
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            color: Colors.black,
            onPressed: (){ 
              //Navigator.of(context).pop();
              print('Pressed arrow back on main notice board');
              },
            ),
          title: Text("Notice Board",
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'BalooChettan2',
                      fontWeight: FontWeight.w700,
                    )
                  ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add), 
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                   builder: (context) => UploadNotice()
                   ),
                );
              },
              color: Colors.black,
            ),
          ],
        ),
        body: buildNoticeFeed(),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom:25.0),
          child: FloatingActionButton(
            backgroundColor: Colors.grey[300],
            mini: true,
            onPressed: () {
              setState(() {
                scrollToTop();
              });
            },
            // scrollToTop,
            child: Icon(Icons.arrow_upward,color: Colors.black),
        ),
      ),
      );
  }
}
