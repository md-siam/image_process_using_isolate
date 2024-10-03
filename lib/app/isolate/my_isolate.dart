import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class MyIsolate {
  // Timer to check whether the Isolate is
  // closed properly or not
  static void _startTheTimer() {
    int value = 0;
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      log("Repeat task every ${value++}");
    });
  }

  // Isolate method for picking gallery image
  static Future<void> pickGalleryImage(List args) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(args[0]);
    final ImagePicker imagePicker = ImagePicker();

    _startTheTimer();

    await imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80).then((value) async {
      //
      if (value?.path == null) {
        Future.delayed(Duration.zero, () {
          Isolate.exit();
        });
        return;
      }

      //
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: value!.path,
        compressFormat: ImageCompressFormat.jpg,
        aspectRatio: const CropAspectRatio(ratioX: 100, ratioY: 100),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.purple,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop',
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      //
      if (croppedFile != null) {
        final SendPort sendPort = args[1];
        sendPort.send(croppedFile.path.toString());
        //
        Future.delayed(Duration.zero, () {
          Isolate.exit();
        });
      }
    });
  }

  // Isolate method for picking camera image
  static Future<void> pickCameraImage(List args) async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(args[0]);
    final ImagePicker imagePicker = ImagePicker();

    _startTheTimer();

    await imagePicker.pickImage(source: ImageSource.camera, imageQuality: 80).then((value) async {
      //
      if (value?.path == null) {
        Future.delayed(Duration.zero, () {
          Isolate.exit();
        });
        return;
      }

      //
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: value!.path,
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
      //
      if (croppedFile != null) {
        final SendPort sendPort = args[1];
        sendPort.send(croppedFile.path.toString());
        //
        Future.delayed(Duration.zero, () {
          Isolate.exit();
        });
      }
    });
  }
}
