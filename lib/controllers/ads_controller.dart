import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/ads_model.dart';

class AdsController extends GetxController {
  var ads = AdsModel().obs;

  var listAds = <AdsModel>[].obs;
  var listSearch = <AdsModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Ads controller");
  }

  ///On recupère la liste des Ads
  Future<List<AdsModel>?> getAds() async {
    try {
      var res = await Setting.fAds.get();

      var list =
          res.docs.map((e) {
            var r = AdsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Ads :::$e");
      return null;
    }
  }

  Future<AdsModel?> getOneAds(String key) async {
    try {
      var e = await Setting.fAds.doc(key).get();
      var r = AdsModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Ads :::$e");
      return null;
    }
  }

  Future<String?> addAds() async {
    try {
      var res = await Setting.fAds.add(ads.value.toJson());
      ads.value = AdsModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateAds({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fAds.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listAds.isNotEmpty) {
      var doc = await Setting.fAds.doc(listAds.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<AdsModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fAds.limit(1000);
    if (doc != null) {
      ref = Setting.fAds.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<AdsModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = AdsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return AdsModel();
          }
        }).toList();
    listAds.addAll(rs);
    listAds.value = removeDub(listAds);
    update();
    return rs;
  }

  List<AdsModel> removeDub(List<AdsModel> list) {
    Map<String, AdsModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<AdsModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fAds.doc(val).get();
      var dt = AdsModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <AdsModel>[dt];

      listSearch.refresh();
      update();
      return <AdsModel>[dt];
    }

    var byeq =
        (exact ?? false)
            ? false
            : await Get.defaultDialog<bool>(
              title: "Recherche",
              middleText: "Vous cherchez la valeur exacte ou approximative?",
              textCancel: "Exacte",
              textConfirm: "Approximative",
              onConfirm: () {
                Get.back(result: true);
              },
            );
    Setting.showMessage("En cours", "Nous effectuons la recherche");
    var ref =
        (byeq ?? false)
            ? Setting.fAds.where(key, isGreaterThanOrEqualTo: val).limit(100)
            : Setting.fAds.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<AdsModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = AdsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return AdsModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountAds() async {
    try {
      var res = await Setting.fAds.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Ads $e");
      return null;
    }
  }

  Future<List<AdsModel>?> getAdsOfUser(String keyUser) async {
    try {
      //remplacer BDColumnNames.Ads_idOfUser par la propriété qui est le id de User dans Ads
      var res =
          await Setting.fAds
              .where(BDColumnNames.Ads_id_user_admin, isEqualTo: keyUser)
              .get();

      var list =
          res.docs.map((e) {
            var r = AdsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Ads of User :::$e");
      return null;
    }
  }
}
