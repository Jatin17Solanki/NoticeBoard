/*  REQUIREMENTS :
      1)Abbreviated college name is required
      2) cached network image with placeholder for full screen image
      3)check if it is possible to share files (currently only images can be shared)
      4)like(favorite)  feature not implemented
      5)display a one time pop up stating that the downloaded files are stored under inernalstorage -> downloads 
        -> noticeboard
      6) filter notice for admin
      7) automatic filter notice for user
      8) starred notices page
      9) notifications
      10) edit/delete notice by admin
  DONE    11) create a global variable to store the path of diretoryy where the downloaded file should be saved
  DONE    12) in the uploadnotice page use the cupertion box defined in the constants page for showBranchValidation
      13) show a template when there are no notices to be viewed
      14)Required user and admin model
      

      BUGS:
        1) set pdf file upload size limit
        2)if a downloaded file is manually deleted from the directory , it does not reflect on the app
        3)provide storage access
        4)no internet error
    
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notice_board/shared/custom_image.dart';
import 'package:notice_board/shared/full_screen_image.dart';
import 'package:notice_board/shared/view_pdf.dart';
import 'notice_icons.dart';
// import 'package:flutter_downloader/flutter_downloader.dart'; //step 1

List<String> imageFormats = [
  'jpg',
  'jpeg',
  'png',
  'svg',
  'tiff',
  'gif'
]; //GLOBAL
Color impColor = Colors.yellowAccent[100];

class Notice extends StatefulWidget {
  final String noticeId;
  final String mediaUrl;
  final String fileExtension;
  final String noticeTitle;
  final String noticeDescription;
  final String uploadDate;
  final String deptName;
  final bool isImportant;
  // final dynamic favorite;

  final TargetPlatform platform; //step 5

  Notice({
    this.noticeId,
    this.mediaUrl,
    this.fileExtension,
    this.noticeTitle,
    this.noticeDescription,
    this.uploadDate,
    this.deptName,
    this.isImportant,
    // this.favorite,
    this.platform, //step 6
  });

  factory Notice.fromDocument(DocumentSnapshot doc, TargetPlatform platform) {
    return Notice(
      noticeId: doc['noticeId'],
      mediaUrl: doc['mediaUrl'],
      fileExtension: doc['fileExtension'],
      noticeTitle: doc['noticeTitle'],
      noticeDescription: doc['noticeDescription'],
      uploadDate: doc['uploadDate'],
      deptName: doc['deptName'],
      isImportant: doc['isImportant'],
      // favorite: doc['favorite'],
      platform: platform,
    );
  }

  @override
  _NoticeState createState() => _NoticeState(
        noticeId: this.noticeId,
        mediaUrl: this.mediaUrl,
        fileExtension: this.fileExtension,
        noticeTitle: this.noticeTitle,
        noticeDescription: this.noticeDescription,
        uploadDate: this.uploadDate,
        deptName: this.deptName,
        isImportant: this.isImportant,
        // favorite: this.favorite,
        platform: this.platform, //step 7
      );
}

class _NoticeState extends State<Notice> {
  String noticeId;
  String noticeTitle;
  String noticeDescription;
  String uploadDate;
  String deptName;
  bool isImportant;
  // Map favorite;
  String mediaUrl;
  String fileExtension;

  final TargetPlatform platform; //step 8

  _NoticeState(
      {this.noticeId,
      this.mediaUrl,
      this.fileExtension,
      this.noticeTitle,
      this.noticeDescription,
      this.uploadDate,
      this.deptName,
      this.isImportant,
      // this.favorite,
      this.platform //step 9
      });

  showNoticeHeader() {
    return Container(
      height: imageFormats.contains(fileExtension)
          ? 305
          : 250, //if image height is 305 else 250
      decoration: BoxDecoration(
        color: isImportant ? impColor : Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: Text(
              "$noticeTitle",
              style: TextStyle(
                fontSize: 20,
                // fontFamily: 'BalooChettan2',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Divider(
            color: Colors.black,
            height: 20,
            thickness: 2,
            indent: 1,
            endIndent: 1,
          ),
          imageFormats.contains(fileExtension)
              ?
              //if its an image then...
              Container(
                  height: 200,
                  child: GestureDetector(
                    onTap: () {
                      if( imageFormats.contains(fileExtension)) {
                        return Navigator.push(context, MaterialPageRoute(
                          builder: (context) => FullScreen(mediaUrl: mediaUrl)
                          )
                        );
                      } else {
                        return null;
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // child: Image(
                      //   image: NetworkImage('$mediaUrl'),
                      // ),
                      child: cachedNetworkImage(mediaUrl),
                    ),
                  ),
                )
              //if its a document then..
              : fileExtension == 'pdf'
                  ?
                  //if document is a pdf then open in app
                  InkWell(
                      onTap: () {
                        return prepareTestPdf(mediaUrl).then((path) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    FullPdfViewerScreen(path)),
                          );
                        });
                      },
                      child: Container(
                        height: 145,
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: 20),
                            Icon(
                              Icons.picture_as_pdf,
                              size: 75,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Tap to view",
                              style: TextStyle(
                                fontSize: 20,
                                // fontFamily: 'BalooChettan2',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  //non pdf document
                  : Container(
                      height: 145,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Please download the document \n       to view its content!',
                            style: TextStyle(
                                // fontFamily: 'BalooChettan2',
                                fontWeight: FontWeight.w500,
                                fontSize: 20),
                          ),
                          SizedBox(height: 10),
                          Icon(
                            Icons.description,
                            size: 30,
                          )
                        ],
                      )),
          Divider(
            color: Colors.black54,
            height: 20,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
          Row(
            children: <Widget>[
              SizedBox(width: 20),
              (deptName == null || deptName.isEmpty)
                  ? Expanded(
                      child: Text(
                      "MIT", //college name
                      style: TextStyle(
                        fontSize: 15,
                        // fontFamily: 'BalooChettan2',
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                  : Expanded(
                      child: Text(
                      "Dept Of $deptName", //needs modification
                      style: TextStyle(
                        fontSize: 15,
                        // fontFamily: 'BalooChettan2',
                        fontWeight: FontWeight.w600,
                      ),
                    )),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "$uploadDate",
                  style: TextStyle(
                    fontSize: 15,
                    // fontFamily: 'BalooChettan2',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 20),
            ],
          ),
        ],
      ),
    );
  }

  showDescriptionBox() {
    if (noticeDescription == null || noticeDescription.isEmpty) {
      return SizedBox(height: 1);
    } else {
      return Container(
          height: 55,
          decoration: BoxDecoration(
            color: isImportant ? impColor : Colors.white,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "$noticeDescription",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontFamily: 'BalooChettan2',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 20),
            ],
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        children: [
          showNoticeHeader(), //includes title, image/pdf area and deptName and date
          showDescriptionBox(),
          SizedBox(height: 5),
          //contains a row of icons to perform download,share and like
          NoticeFooter(
              //final step
              platform: platform,
              noticeTitle: noticeTitle,
              mediaUrl: mediaUrl,
              fileExtension: fileExtension,
              isImportant: isImportant,
              noticeDescription: noticeDescription,
            ),
        ],
      ),
    );
  }
}
