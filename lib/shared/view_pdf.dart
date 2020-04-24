//View pdf from a url in app

import 'package:path_provider/path_provider.dart';
import 'package:flutter_full_pdf_viewer/flutter_full_pdf_viewer.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<String> prepareTestPdf(String pdfUrl) async {
  final filename = pdfUrl.substring(pdfUrl.lastIndexOf("/") + 1);
  var request = await HttpClient().getUrl(Uri.parse(pdfUrl));
  var response = await request.close();
  var bytes = await consolidateHttpClientResponseBytes(response);
  String dir = (await getApplicationDocumentsDirectory()).path;
  File file = new File('$dir/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

class FullPdfViewerScreen extends StatelessWidget {
  final String pdfPath;

  FullPdfViewerScreen(this.pdfPath);
  @override
  Widget build(BuildContext context) {
    return PDFViewerScaffold(
        appBar: AppBar(
          // backgroundColor: Colors.blueGrey[100],
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            color: Colors.black,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text("Document",
              style: TextStyle(
                color: Colors.black,
                // fontFamily: 'BalooChettan2',
                fontWeight: FontWeight.w700,
              )),
          centerTitle: true,
        ),
        path: pdfPath);
  }
}
