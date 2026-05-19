import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import '../core/config/app_secrets.dart';
import '../utils/Setting.dart';

class HomeController extends GetxController {
  var isLoaded = false.obs;
  var isConnect = false.obs;

  StreamSubscription? con;
  bool on = false;
  late StreamSubscription appBlock;

  late StreamSubscription appAjour;
  String openaikey = AppSecrets.openAiApiKey;

  var isAjour = true.obs;
  var isBlock = false.obs;
  var source = "".obs;
  StreamSubscription? mj;
  late GetStorage storage;
  @override
  void onInit() {
    super.onInit();
    storage = GetStorage(Setting.storageName);
    printDebug("home controller is here");

    appBlock = isBlock.listen((v) {
      if (v) {
        Get.defaultDialog(
          title: "Mise A jour",
          barrierDismissible: false,
          middleText: "Votre version a expiré, vous devez la mettre à jour",
          textCancel: "Non",
          textConfirm: "Télécharger",
          onConfirm: () {
            Setting.openUrl(source.value);
          },
          onCancel: () {
            SystemNavigator.pop();
          },
        );
      }
    });
    appAjour = isAjour.listen((v) {
      if (!v) {
        Get.defaultDialog(
          title: "Mise A Jour",
          middleText: "Nouvelle Mise A jour Disponible à télécharger",
          textCancel: "Plus tard",
          textConfirm: "Télécharger",
          onConfirm: () {
            Setting.openUrl(source.value);
          },
          onCancel: () {},
        );
      }
    });
    mj = Setting.fMiseAjour.doc("app").snapshots().listen((event) {
      if (event.data() == null) return;
      var res = event.data() as Map<String, dynamic>;
      printDebug("data ::: $res");
      double myVersion = double.parse(Setting.version);
      double? minVersion = double.tryParse(res["minVersion"].toString());
      double? actualVersion = double.tryParse(res["actualVersion"].toString());

      if (minVersion != null && minVersion > myVersion) {
        printDebug("application bloquée");
        isBlock.value = true;
        isAjour.value = false;
        source.value = res["source"].toString();
        isBlock.refresh();
      }

      if (actualVersion != null && actualVersion > myVersion) {
        printDebug("application non à jour");
        isAjour.value = false;
        isAjour.refresh();
        source.value = res["source"].toString();
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    // timer.cancel();
    con?.cancel();
    appAjour.cancel();
    appBlock.cancel();
  }

  void setCopyToClipboard(String text) {
    Get.defaultDialog(
      title: "Copier texte?",
      middleText: text,
      onCancel: () {},
      onConfirm: () {
        Get.back();
        Clipboard.setData(
          ClipboardData(text: text),
        ).then((value) => Setting.showMessage("$text", "copié avec succès"));
      },
    );
  }

  List<T> removeDub<T>(List<T> list) {
    Map<String, T> map = {};
    for (var e in list) {
      dynamic d = e;
      map.addAll({d.key!: e});
    }
    return map.values.toList();
  }

  // Future<bool?> deleteFile(String key) async {
  //   try {
  //     firebase_storage.Reference reference = firebase_storage
  //         .FirebaseStorage
  //         .instance
  //         .ref()
  //         .child(key);
  //     await reference.delete();
  //     return true;
  //   } catch (e) {
  //     printDebug("error : $e");
  //     return null;
  //   }
  // }

  // Future<Map<String, String>> sendPic(List<String> paths) async {
  //   try {
  //     var list = <String>[];
  //     var map = <String, String>{};
  //     for (var v in paths) {
  //       String filename =
  //           "/${Setting.userCtrl.user.value.nom}$v" /* + DateTime.now().millisecond.toString() */;
  //       firebase_storage.Reference reference = firebase_storage
  //           .FirebaseStorage
  //           .instance
  //           .ref()
  //           .child(filename);
  //       firebase_storage.UploadTask uploadtask = reference.putFile(File(v));
  //       firebase_storage.TaskSnapshot tasksnapshot = await uploadtask
  //           .whenComplete(() => uploadtask.snapshot);
  //       String downloadurl = await tasksnapshot.ref.getDownloadURL();

  //       map[filename] = downloadurl;

  //       list.add(downloadurl);
  //     }
  //     return map;
  //   } catch (e) {
  //     printDebug("error : $e");
  //     return {};
  //   }
  // }
}
