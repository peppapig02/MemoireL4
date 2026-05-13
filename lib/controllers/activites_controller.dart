import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/activites_model.dart';

//récupérer les activités dans Firestore
//ajouter, modifier, chercher, compter, paginer les données
//gérer une liste observable pour mettre à jour la vue en temps réel

class ActivitesController extends GetxController {
  var activites = ActivitesModel().obs;
// observable de GetX. Si les données changent, l’interface liée se met à jour toute seule.


  var listActivites = <ActivitesModel>[].obs;
  var listSearch = <ActivitesModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Activites controller");
  }

  ///On recupère la liste des Activites
  Future<List<ActivitesModel>?> getActivites() async {
    try {
      var res = await Setting.fActivites.get();

      var list =
          res.docs.map((e) {
            var r = ActivitesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Activites :::$e");
      return null;
    }
  }

  Future<ActivitesModel?> getOneActivites(String key) async {
    try {
      var e = await Setting.fActivites.doc(key).get();
      var r = ActivitesModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Activites :::$e");
      return null;
    }
  }

  Future<String?> addActivites() async {
    try {
      var res = await Setting.fActivites.add(activites.value.toJson());
      activites.value = ActivitesModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateActivites({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fActivites.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listActivites.isNotEmpty) {
      var doc = await Setting.fActivites.doc(listActivites.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<ActivitesModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fActivites.limit(1000);
    if (doc != null) {
      ref = Setting.fActivites.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<ActivitesModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = ActivitesModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return ActivitesModel();
          }
        }).toList();
    listActivites.addAll(rs);
    listActivites.value = removeDub(listActivites);
    update();
    return rs;
  }

  List<ActivitesModel> removeDub(List<ActivitesModel> list) {
    Map<String, ActivitesModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<ActivitesModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fActivites.doc(val).get();
      var dt = ActivitesModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <ActivitesModel>[dt];

      listSearch.refresh();
      update();
      return <ActivitesModel>[dt];
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
            ? Setting.fActivites
                .where(key, isGreaterThanOrEqualTo: val)
                .limit(100)
            : Setting.fActivites.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<ActivitesModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = ActivitesModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return ActivitesModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountActivites() async {
    try {
      var res = await Setting.fActivites.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Activites $e");
      return null;
    }
  }

  Future<List<ActivitesModel>?> getActivitesOfUser(String keyUser) async {
    try {
      //remplacer BDColumnNames.Activites_idOfUser par la propriété qui est le id de User dans Activites
      var res =
          await Setting.fActivites
              .where(BDColumnNames.Activites_id_user, isEqualTo: keyUser)
              .get();

      var list =
          res.docs.map((e) {
            var r = ActivitesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Activites of User :::$e");
      return null;
    }
  }
}
