import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'noticePost.dart'; //to access the list imageFormats, Color impColor
import 'package:notice_board/shared/constants.dart'; //for cupertino box

final String downloadDirectory = 'Notice_Board';

class NoticeFooter extends StatefulWidget {
  final TargetPlatform platform;
  final String noticeTitle;
  final String fileExtension;
  final String mediaUrl;
  final String noticeDescription;
  final bool isImportant;

  NoticeFooter(
      {this.platform, this.noticeTitle, this.fileExtension, this.mediaUrl, this.noticeDescription, this.isImportant});

  @override
  _NoticeFooterState createState() => _NoticeFooterState(
      noticeTitle: noticeTitle,
      fileExtension: fileExtension,
      mediaUrl: mediaUrl,
      noticeDescription:noticeDescription,
      isImportant: isImportant
    );
}

class _NoticeFooterState extends State<NoticeFooter> {
  
  String noticeTitle;
  String fileExtension;
  String mediaUrl;
  String noticeDescription;
  final bool isImportant;

  _NoticeFooterState({this.noticeTitle, this.fileExtension, this.mediaUrl, this.noticeDescription, this.isImportant});

  Directory _downloadsDirectory;

  bool _isLoading;
  bool _permissionReady;
  String _localPath;
  ReceivePort _port = ReceivePort();

  _TaskInfo downloadTask;
  _ItemHolder itemTask;

  @override
  void initState() {
    super.initState();

    // checkForPermission();

    
    initDownloadsDirectoryState();

    _bindBackgroundIsolate();

    FlutterDownloader.registerCallback(downloadCallback);

    _isLoading = true;
    _permissionReady = false;

    _prepare();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  //Method to get the path of the downloads directory
  //the path is _downloadsDirectory.path
  Future<void> initDownloadsDirectoryState() async {
    Directory downloadsDirectory;
    try {
      downloadsDirectory = await DownloadsPathProvider.downloadsDirectory;
    } on PlatformException {
      print('Could not get the downloads directory');
    }

    if (!mounted) return;

    setState(() {
      _downloadsDirectory = downloadsDirectory;
    });
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      print('UI Isolate Callback: $data');
      DownloadTaskStatus status = data[1];
      int progress = data[2];

      final task = downloadTask;
      if (task != null) {
        setState(() {
          task.status = status;
          task.progress = progress;
        });
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    print(
        'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  onTapDownload() {
    if (itemTask.task.status == DownloadTaskStatus.complete) {
      return _openDownloadedFile(itemTask.task).then((success) {
        if (!success) {
          Scaffold.of(context)
              .showSnackBar(SnackBar(content: Text('Cannot open this file')));
        }
      });
    } else {
      return null;
    }
  }

  //To share image
  Future<void> _shareImageFromUrl(String url,String fileName,String description) async {

    String desc = description ?? '';
    print(' description : $description');
    try{
      var request = await HttpClient().getUrl(Uri.parse('$url'));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      await Share.file('$fileName', '$fileName.jpg', bytes, 'image/jpg',
      text: '${fileName.toUpperCase()}\n\n$desc');
    } catch(e) {
      print('error is $e');
    }
    
  }

  Widget showNoticeFooter() {

    checkForPermission();

    return Container(
      decoration: BoxDecoration(
        color: isImportant ? impColor : Colors.white,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      height: 48.0,
      child: new Stack(
        children: <Widget>[
          new Container(
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildActionForTask(itemTask.task),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () async { 
                    if( !imageFormats.contains(fileExtension)) {
                      showValidationMessage(
                        context: context, 
                        title: 'This document cannot be shared!'
                      );
                      return;
                    }
                    await _shareImageFromUrl(mediaUrl,noticeTitle,noticeDescription);
                   }
                ),
                IconButton(
                    icon: Icon(Icons.favorite),
                    onPressed: () {
                      print('tapped fav button');
                    }),
              ],
            ),
          ),
          itemTask.task.status == DownloadTaskStatus.running ||
                  itemTask.task.status == DownloadTaskStatus.paused
              ? new Positioned(
                  left: 0.0,
                  right: 0.0,
                  child: new LinearProgressIndicator(
                    value: itemTask.task.progress / 100,
                    backgroundColor: Colors.black45,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
              : new Text('')
        ].where((child) => child != null).toList(),
      ),
    );
  }

  checkForPermission() {
    _checkPermission().then((hasGranted) {
      setState(() {
        _permissionReady = hasGranted;
      });
    });
  }

  // Widget showPermissionOption() {

  //   _checkPermission().then((hasGranted) {
  //     setState(() {
  //       _permissionReady = hasGranted;
  //     });
  //   });
  //   return Text('');
  //   // return Container(
  //   //   height: 200,
  //   //   child: Center(
  //   //     child: Column(
  //   //       mainAxisSize: MainAxisSize.min,
  //   //       crossAxisAlignment: CrossAxisAlignment.center,
  //   //       children: [
  //   //         // Padding(
  //   //         //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
  //   //         //   child: Text(
  //   //         //     'Please grant accessing storage permission to continue -_-',
  //   //         //     textAlign: TextAlign.center,
  //   //         //     style: TextStyle(color: Colors.blueGrey, fontSize: 18.0),
  //   //         //   ),
  //   //         // ),
  //   //         // SizedBox(
  //   //         //   height: 32.0,
  //   //         // ),
  //   //         FlatButton(
  //   //             onPressed: () {
  //   //               _checkPermission().then((hasGranted) {
  //   //                 setState(() {
  //   //                   _permissionReady = hasGranted;
  //   //                 });
  //   //               });
  //   //             },
  //   //             child: Text(
  //   //               'Retry',
  //   //               style: TextStyle(
  //   //                   color: Colors.blue,
  //   //                   fontWeight: FontWeight.bold,
  //   //                   fontSize: 20.0),
  //   //             ))
  //   //       ],
  //   //     ),
  //   //   ),
  //   // );
  // }

  Widget _buildActionForTask(_TaskInfo task) {
    print('task status = ${task.status}');
    print('task name = ${task.name}');
    if (task.status == DownloadTaskStatus.undefined ||
        task.status == DownloadTaskStatus.canceled) {
      return IconButton(
        onPressed: () {
          _requestDownload(task);
        },
        icon: new Icon(Icons.file_download),
      );
    } else if (task.status == DownloadTaskStatus.running) {
      return Row(
        children: <Widget>[
          IconButton(
            onPressed: () {
              _cancelDownload(task);
            },
            icon: new Icon(
              Icons.cancel,
              color: Colors.red,
            ),
          ),
        ],
      );
    } else if (task.status == DownloadTaskStatus.complete) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
              onTap: () => onTapDownload(),
              child: Text(
                'View',
                style: TextStyle(
                    // fontFamily: 'BalooChettan2',
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              )),
          SizedBox(
            width: 30,
          ),
          IconButton(
            onPressed: () {
              _delete(task);
            },
            icon: Icon(
              Icons.delete_forever,
              color: Colors.black,
              size: 25,
            ),
          )
        ],
      );
    } else if (task.status == DownloadTaskStatus.canceled) {
      return new Text('Canceled', style: new TextStyle(color: Colors.red));
    } else if (task.status == DownloadTaskStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Text('Failed', style: new TextStyle(color: Colors.red,fontFamily: 'BalooChettan2')),
            IconButton(
            onPressed: () {
              _retryDownload(task);
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.black,
            ),
          )
        ],
      );
    } else { //when internet is off
      return IconButton(
        onPressed: () {
          showValidationMessage(
            context: context,
            title: 'Cannot download!\nPlease check your internet connection!'
          );
        },
        icon: new Icon(Icons.file_download),
      );
    }
  }

  void _requestDownload(_TaskInfo task) async {
    String filename = noticeTitle.replaceAll(" ", "_") + "." + fileExtension;
    // print(' filename is $filename');

    task.taskId = await FlutterDownloader.enqueue(
        url: task.link,
        headers: {"auth": "test_for_sql_encoding"},
        savedDir: _localPath,
        showNotification: true,
        openFileFromNotification: true,
        fileName: filename //the downloaded media will be stored with this name
        );
  }

  void _cancelDownload(_TaskInfo task) async {
    await FlutterDownloader.cancel(taskId: task.taskId);
  }

  void _retryDownload(_TaskInfo task) async {
    String newTaskId = await FlutterDownloader.retry(taskId: task.taskId);
    task.taskId = newTaskId;
  }

  Future<bool> _openDownloadedFile(_TaskInfo task) {
    return FlutterDownloader.open(taskId: task.taskId);
  }

  void _delete(_TaskInfo task) async {
    await FlutterDownloader.remove(
        taskId: task.taskId, shouldDeleteContent: true);
    await _prepare();
    setState(() {});
  }

  Future<bool> _checkPermission() async {
    if (widget.platform == TargetPlatform.android) {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
      if (permission != PermissionStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.storage]);
        if (permissions[PermissionGroup.storage] == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<Null> _prepare() async {
    final tasks = await FlutterDownloader.loadTasks();

    //mention name and link here
    String name = noticeTitle.replaceAll(" ", "_");
    String link = mediaUrl;

    downloadTask = _TaskInfo(link: link, name: name);
    itemTask = _ItemHolder(name: downloadTask.name, task: downloadTask);

    tasks?.forEach((task) {
      _TaskInfo info = downloadTask;
      if (info.link == task.url) {
        info.taskId = task.taskId;
        info.status = task.status;
        info.progress = task.progress;
      }
    });

    // _permissionReady = await _checkPermission();

    //creats a directory callled notice_board in the downloads folder
    _localPath =
        _downloadsDirectory.path + Platform.pathSeparator + downloadDirectory;
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
      print('in notice');
    return Container(
      height: 48.0,
      child: Builder(
          builder: (context) => _isLoading
              ? Center(
                  child: new CircularProgressIndicator(),
                )
              : showNoticeFooter()
      ),
    );
  }

}

class _TaskInfo {
  final String name;
  final String link;

  String taskId;
  int progress = 0;
  DownloadTaskStatus status = DownloadTaskStatus.undefined;

  _TaskInfo({this.name, this.link});
}

class _ItemHolder {
  final String name;
  final _TaskInfo task;

  _ItemHolder({this.name, this.task});
}
