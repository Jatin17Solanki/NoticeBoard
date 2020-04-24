import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:notice_board/shared/constants.dart';
import 'package:notice_board/shared/loading.dart';
import 'package:open_file/open_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; //for date format

// import 'package:notice_board/models/admin_model.dart';

class UploadNotice extends StatefulWidget {
  // final Admin admin;
  // UploadNotice({this.admin});

  @override
  _UploadNoticeState createState() => _UploadNoticeState(
      // admin: this.admin
      );
}

class _UploadNoticeState extends State<UploadNotice> {
  // Admin admin;
  // _UploadNoticeState({this.admin});

  File imageFile;
  File docFile;
  File uploadFile; //upload file will either have docFile or imageFile
  String fileExtension;
  String fileName;
  String filePath;

  final DateTime timestamp = DateTime.now();
  final noticeRef = Firestore.instance.collection('noticePosts');
  final branchListRef = Firestore.instance.collection('branchList');
  final StorageReference storageRef = FirebaseStorage.instance.ref();
  String noticeId = Uuid().v4();
  bool isUploading = false;
  bool isImportant = false;
  Map<String, bool> branchMap = new Map<String, bool>();

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController deptNameController = TextEditingController();
  final List<String> yearList = [
    'General',
    ' First',
    ' Second',
    ' Third',
    ' Fourth',
    ' Fifth'
  ];
  final List<String> branchSelectedList = [];
  String yearValue;
  String branchValue;
  String collegeId = 'OCbfAv2MjME0yGsjHUH8';

  Widget showPreview() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
            border: Border.all(color: Colors.grey, width: 1.5)),
        height: 250,
        child: Column(
          children: <Widget>[
            Container(
              height: 180,
              child: Center(
                  child: uploadFile == null
                      ? Text(
                          'Preview',
                          style: TextStyle(
                              fontFamily: 'BalooChettan2',
                              fontWeight: FontWeight.w400,
                              fontSize: 30.0,
                              color: Colors.black),
                        )
                      : imageFile != null
                          ? AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: FileImage(imageFile),
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                      child: Text(
                                    'Tap to view',
                                    style: TextStyle(
                                        fontFamily: 'BalooChettan2',
                                        fontSize: 25.0),
                                  )),
                                  Center(
                                    child: IconButton(
                                        icon: Icon(Icons.open_with),
                                        iconSize: 35.0,
                                        onPressed: () {
                                          OpenFile.open(filePath);
                                        }),
                                  )
                                ],
                              ),
                            )),
            ),
            Divider(
              color: Colors.black87,
              height: 10,
              thickness: 1.5,
              indent: 2,
              endIndent: 2,
            ),
            ListTile(
                title: Text(
                  uploadFile == null ? 'File name' : '$fileName',
                  style: TextStyle(
                    fontFamily: 'BalooChettan2',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: uploadFile == null
                    ? null
                    : imageFile == null
                        ? Icon(Icons.description)
                        : Icon(Icons.image))
          ],
        ),
      ),
    );
  }

  Widget showForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              textCapitalization: TextCapitalization.words,
              decoration: textInputDecoration.copyWith(
                  labelText: 'Title',
                  hintText: 'Required',
                  fillColor: Colors.grey[200]),
              // autovalidate: true,
              validator: (value) {
                if (value.isEmpty)
                  return 'Please enter a title!';
                else if (value.trim().length > 21)
                  return 'Too long!';
                else
                  return null;
              },
            ),
            SizedBox(height: 10.0),
            TextFormField(
                controller: descriptionController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                decoration: textInputDecoration.copyWith(
                    labelText: 'Description',
                    hintText: 'Optional',
                    fillColor: Colors.grey[200])),
            SizedBox(height: 10.0),
            TextFormField(
                controller: deptNameController,
                textCapitalization: TextCapitalization.characters,
                decoration: textInputDecoration.copyWith(
                    labelText: 'Department Name',
                    hintText: 'Optional - Enter abbreviation',
                    fillColor: Colors.grey[200])),
            SizedBox(height: 10.0),
            DropdownButtonFormField(
              decoration: textInputDecoration,
              validator: (value) {
                if (!yearList.contains(value))
                  return "Please select a year!";
                else
                  return null;
              },
              value: yearValue,
              hint: Text('Select a year'),
              items: yearList.map((value) {
                return DropdownMenuItem(value: value, child: Text('$value'));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  yearValue = value;
                });
              },
            ),
            SizedBox(height: 10.0),
            RaisedButton(
                child: Text(
                  "View branch options",
                  style: TextStyle(fontFamily: "BalooChettan2", fontSize: 17.0),
                ),
                color: Colors.grey[200],
                elevation: 10.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    side: BorderSide(color: Colors.grey)),
                onPressed: () => showBranchOptions())
          ],
        ),
      ),
    );
  }

  void showBranchOptions() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: Colors.grey[400],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20, bottom: 10, right: 40, left: 40),
                        child: Center(
                          child: StreamBuilder(
                              stream: branchListRef.document(collegeId).snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData)
                                  return Text("loading");
                                else {
                                  List<DropdownMenuItem<String>> blist = [];
                                  snapshot.data['blist'].forEach((branch) {

                                    branchMap.putIfAbsent(branch, () => false); //initializing the branches

                                    blist.add(DropdownMenuItem(
                                      value: branch,
                                      child: Text(branch),
                                    ));
                                  });
                                  return DropdownButtonFormField(
                                    decoration: InputDecoration(
                                        fillColor: Colors.grey[300],
                                        filled: true,
                                        enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.black, width: 2.0),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15.0)))),
                                    hint: Text('Select required branches'),
                                    items: blist,
                                    value: branchValue,
                                    onChanged: (value) {
                                      setState(() {
                                         branchValue = value;
                                      });
                                      print(value);
                                      if (!branchSelectedList.contains(value)) {
                                        branchSelectedList.add(value);
                                        setState(() {});
                                      }
                                    },
                                  );
                                }
                              }),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.375,
                        child: Padding(
                          padding: EdgeInsets.only(right: 70, left: 70),
                          child: ListView.builder(
                              itemCount: branchSelectedList.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.black, width: 2.0),
                                        borderRadius: BorderRadius.circular(15),
                                        color: Colors.amber[100]),
                                    child: ListTile(
                                      title: Text(branchSelectedList[index]),
                                      trailing: IconButton(
                                          icon: Icon(Icons.cancel),
                                          onPressed: () {
                                            // branchSelectedList.remove(branchSelectedList[index]);
                                            setState(() {
                                              branchSelectedList
                                                  .remove(branchSelectedList[index]);
                                            });
                                          }),
                                    ),
                                  ),
                                );
                              }),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  handleChooseImage(ImageSource source) async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: source);

    setState(() {
      imageFile = file;
      uploadFile = file;
      fileExtension = file.toString().replaceAll("'", "").split('.').last;
      fileName = file.toString().replaceAll("'", "").split('/').last;
      docFile = null;
      // print('ifile : $file');
      // print('iFile name: $fileName');
      // print('iFile extension : $fileExtension');
    });
  }

  handleChooseDoc() async {
    Navigator.pop(context);
    try {
      filePath = await FilePicker.getFilePath(
        type: FileType.any,
      );
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }

    if (!mounted) return;

    setState(() {
      fileExtension = filePath.split('.').last;
      fileName = filePath.split('/').last;
      docFile = File(filePath);
      uploadFile = docFile;
      imageFile = null;
      // print('dFile in file format is $docFile');
      // print('dfileExtension : $fileExtension');
    });
  }

  selectFile(parentContext) {
    return showCupertinoDialog(
        context: parentContext,
        builder: (context) {
          return CupertinoAlertDialog(
            actions: [
              FlatButton(
                  onPressed: () => handleChooseImage(ImageSource.camera),
                  child: Text(
                    'Photo from Camera',
                    style: TextStyle(fontFamily: 'BalooChettan2'),
                  )),
              FlatButton(
                  onPressed: () => handleChooseImage(ImageSource.gallery),
                  child: Text(
                    'Photo from Gallery',
                    style: TextStyle(fontFamily: 'BalooChettan2'),
                  )),
              FlatButton(
                  onPressed: () => handleChooseDoc(),
                  child: Text(
                    'Document file ',
                    style: TextStyle(fontFamily: 'BalooChettan2'),
                  )),
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'BalooChettan2'),
                  )),
            ],
          );
        });
  }

  Future<String> uploadNoticeFile(noticeFile) async {
    StorageUploadTask uploadTask = storageRef
        .child('notice_media/$noticeId.$fileExtension')
        .putFile(noticeFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createNoticeInFirestore({mediaUrl}) {
    // print('Upload file: $uploadFile');
    // print('Image file : $imageFile');
    // print('Document file : $docFile');
    // print('File Extension : $fileExtension');
    // print('Year value: $yearValue');
    // print('Media url: $mediaUrl');

    noticeRef.document(noticeId).setData({
      'noticeId': noticeId,
      'mediaUrl': mediaUrl,
      'fileExtension': fileExtension,
      'noticeTitle': titleController.text,
      'noticeDescription': descriptionController.text,
      'uploadDate': getformatedDate(),
      'timestamp': timestamp,
      'deptName': deptNameController.text,
      'noticeFor': yearValue,
      'isImportant': isImportant,
      'branchMap': branchMap,
      'favorite': null, //should be of type map
      'collegeName': null,
      'collegeId': null,
      'adminId': null,
    });
  }

  String getformatedDate() {
    String date = DateFormat.yMd().format(DateTime.now());
    date = date.replaceAll("/", "-");
    return date;
  }

  initializeBranchMap() {
    branchSelectedList.forEach((branch) { 
      branchMap.update(branch, (value) => true);
    });
    print("Updated\n");
    print(branchMap);
  }  

  handleSubmit() async {
    if (branchSelectedList.isEmpty) {
      showValidationMessage(
        context: context,
        title: 'Please select a branch!'
      );
      return;
    }

    if (!_formKey.currentState.validate()) return;

    initializeBranchMap();

    setState(() {
      isUploading = true;
    });

    String mediaUrl = await uploadNoticeFile(uploadFile);
    createNoticeInFirestore(mediaUrl: mediaUrl);

    setState(() {
      isUploading = false;
      noticeId = Uuid().v4();

      SnackBar snackBar = SnackBar(
          content: Text(
        'Notice Uploaded!',
        style: TextStyle(fontFamily: 'BalooChettan2', fontSize: 20),
      ));
      _scaffoldKey.currentState.showSnackBar(snackBar);

      Timer(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Upload Notice',
          style: TextStyle(
              fontFamily: 'BalooChettan2',
              fontWeight: FontWeight.bold,
              color: Colors.black),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            color: Colors.black,
            onPressed: () {
              Navigator.pop(context);
            }),
        actions: [
          IconButton(
              icon: Icon(Icons.attachment),
              color: Colors.black,
              onPressed: () => selectFile(context)),
          IconButton(
              icon: isImportant ? Icon(Icons.star) : Icon(Icons.star_border),
              color: Colors.black,
              onPressed: () {
                setState(() {
                  isImportant = !isImportant;
                });
              }),
          IconButton(
            icon: Icon(Icons.send),
            color: Colors.black,
            onPressed: isUploading ? null : () => handleSubmit(),
          )
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text(''),
          showPreview(),
          showForm(),
        ],
      ),
    );
  }
}
