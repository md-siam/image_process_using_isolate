import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'isolate/my_isolate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // For image picker
  XFile? _pickedFile;
  String _cropperImagePath = "";
  late ReceivePort _receivePort;
  RootIsolateToken isolateToken = RootIsolateToken.instance!;

  /// For uploading photo from [gallery]
  void photoFromGallery() async {
    _pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
      imageQuality: 80,
    );

    if (_pickedFile != null) {
      _cropImage();

      //
    } else {
      print('No image file chosen');
    }
  }

  /// For uploading photo from [device camera]
  void photoFromCamera() async {
    _pickedFile = await ImagePicker().pickImage(
      requestFullMetadata: false,
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (_pickedFile != null) {
      _cropImage();

      //
    } else {
      print('No image file chosen');
    }
  }

  // Cropping a picked image
  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _pickedFile!.path,
      compressFormat: ImageCompressFormat.jpg,
      aspectRatio: const CropAspectRatio(ratioX: 100, ratioY: 100),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.purple,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop',
          resetButtonHidden: true,
          aspectRatioPickerButtonHidden: true,
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    if (croppedFile != null) {
      //
      setState(() {
        _cropperImagePath = croppedFile.path.toString();
      });

      log(_pickedFile!.path.toString());
      log(_cropperImagePath.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Home Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _cropperImagePath.isEmpty
                ? Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(90),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Icon(Icons.photo),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.file(File(_cropperImagePath)),
                  ),
            const SizedBox(height: 20),
            const Text('Normal Way'),
            Divider(
              thickness: 2,
              color: Theme.of(context).primaryColor,
            ),
            ElevatedButton(
              child: const Text('Open Gallery'),
              onPressed: () {
                photoFromGallery();
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Open Camera'),
              onPressed: () async {
                if (await Permission.camera.status != PermissionStatus.granted) {
                  final status = await Permission.camera.request();

                  if (status == PermissionStatus.denied) return;
                  if (status == PermissionStatus.permanentlyDenied) {
                    openAppSettings();
                    return;
                  }
                }

                photoFromCamera();
              },
            ),
            //
            const SizedBox(height: 30),
            //
            const Text('Isolate'),
            Divider(
              thickness: 2,
              color: Theme.of(context).primaryColor,
            ),

            ElevatedButton(
              onPressed: () async {
                _receivePort = ReceivePort();
                //
                await Isolate.spawn(MyIsolate.pickGalleryImage, [isolateToken, _receivePort.sendPort]);
                //
                //
                _receivePort.listen((message) {
                  if (message != null) {
                    log('Received: $message');

                    setState(() {
                      _cropperImagePath = message;
                    });
                    _receivePort.close();
                  }
                });
                //
              },
              child: const Text('Open Gallery (Using Isolate)'),
            ),
            const SizedBox(height: 10),
            //
            ElevatedButton(
              onPressed: () async {
                _receivePort = ReceivePort();
                //
                await Isolate.spawn(MyIsolate.pickCameraImage, [isolateToken, _receivePort.sendPort]);
                //
                //
                _receivePort.listen((message) {
                  if (message != null) {
                    log('Received: $message');

                    setState(() {
                      _cropperImagePath = message;
                    });
                    _receivePort.close();
                  }
                });
                //
              },
              child: const Text('Open Camera (Using Isolate)'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
