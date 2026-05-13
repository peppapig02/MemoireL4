import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/trending_locations_model.dart';

class Trending_locationsController extends GetxController {
  var trending_locations = Trending_locationsModel().obs;

  var listTrending_locations = <Trending_locationsModel>[].obs;
  var listSearch = <Trending_locationsModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Trending_locations controller");
  }

  ///On recupère la liste des Trending_locations
  Future<List<Trending_locationsModel>?> getTrending_locations() async {
    try {
      var res = await Setting.fTrending_locations.get();

      var list =
          res.docs.map((e) {
            var r = Trending_locationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Trending_locations :::$e");
      return null;
    }
  }

  Future<Trending_locationsModel?> getOneTrending_locations(String key) async {
    try {
      var e = await Setting.fTrending_locations.doc(key).get();
      var r = Trending_locationsModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Trending_locations :::$e");
      return null;
    }
  }

  Future<String?> addTrending_locations() async {
    try {
      var res = await Setting.fTrending_locations.add(
        trending_locations.value.toJson(),
      );
      trending_locations.value = Trending_locationsModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateTrending_locations({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fTrending_locations.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listTrending_locations.isNotEmpty) {
      var doc =
          await Setting.fTrending_locations
              .doc(listTrending_locations.last.key)
              .get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<Trending_locationsModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fTrending_locations.limit(1000);
    if (doc != null) {
      ref = Setting.fTrending_locations.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<Trending_locationsModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = Trending_locationsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return Trending_locationsModel();
          }
        }).toList();
    listTrending_locations.addAll(rs);
    listTrending_locations.value = removeDub(listTrending_locations);
    update();
    return rs;
  }

  List<Trending_locationsModel> removeDub(List<Trending_locationsModel> list) {
    Map<String, Trending_locationsModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<Trending_locationsModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fTrending_locations.doc(val).get();
      var dt = Trending_locationsModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <Trending_locationsModel>[dt];

      listSearch.refresh();
      update();
      return <Trending_locationsModel>[dt];
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
            ? Setting.fTrending_locations
                .where(key, isGreaterThanOrEqualTo: val)
                .limit(100)
            : Setting.fTrending_locations.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<Trending_locationsModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = Trending_locationsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return Trending_locationsModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountTrending_locations() async {
    try {
      var res = await Setting.fTrending_locations.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Trending_locations $e");
      return null;
    }
  }

  Future<List<Trending_locationsModel>?> getTrending_locationsOfUser(
    String keyUser,
  ) async {
    try {
      //remplacer BDColumnNames.Trending_locations_idOfUser par la propriété qui est le id de User dans Trending_locations
      var res =
          await Setting.fTrending_locations
              .where(
                BDColumnNames.Trending_locations_id_user,
                isEqualTo: keyUser,
              )
              .get();

      var list =
          res.docs.map((e) {
            var r = Trending_locationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Trending_locations of User :::$e");
      return null;
    }
  }

  Future<List<Trending_locationsModel>?> getTrending_locationsOfLocations(
    String keyLocations,
  ) async {
    try {
      var res =
          await Setting.fTrending_locations
              .where(
                BDColumnNames.Trending_locations_id_location,
                isEqualTo: keyLocations,
              )
              .get();

      var list =
          res.docs.map((e) {
            var r = Trending_locationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Trending_locations of Locations :::$e");
      return null;
    }
  }

  /// Incrémente le compteur d'une location tendance de manière atomique
  Future<bool> incrementTrendingLocationCount(String trendingLocationId) async {
    try {
      await Setting.firestore.runTransaction((transaction) async {
        // Récupérer le document actuel
        final trendingDoc = await transaction.get(
          Setting.fTrending_locations.doc(trendingLocationId),
        );

        if (!trendingDoc.exists) {
          throw Exception('Location tendance non trouvée');
        }

        // Récupérer le compteur actuel
        final data = trendingDoc.data() as Map<String, dynamic>;
        final currentCount = data[BDColumnNames.Trending_locations_count] ?? 0;

        // Mettre à jour le compteur
        transaction
            .update(Setting.fTrending_locations.doc(trendingLocationId), {
              BDColumnNames.Trending_locations_count: currentCount + 1,
              BDColumnNames.Trending_locations_period:
                  FieldValue.serverTimestamp(),
            });
      });

      return true;
    } catch (e) {
      printDebug("Erreur lors de l'incrémentation du compteur: $e");
      return false;
    }
  }

  /// Crée ou met à jour une location tendance
  Future<String?> createOrUpdateTrendingLocation(String locationId) async {
    try {
      // Vérifier si une entrée existe déjà pour cette location
      final existingTrending =
          await Setting.fTrending_locations
              .where(
                BDColumnNames.Trending_locations_id_location,
                isEqualTo: locationId,
              )
              .get();

      if (existingTrending.docs.isEmpty) {
        // Créer une nouvelle entrée
        trending_locations.value = Trending_locationsModel(
          id_location: locationId,
          count: 1,
          period: DateTime.now().toString(),
          date_create: DateTime.now().toString(),
        );
        return await addTrending_locations();
      } else {
        // Mettre à jour l'entrée existante
        final trendingId = existingTrending.docs.first.id;
        final success = await incrementTrendingLocationCount(trendingId);
        return success ? trendingId : null;
      }
    } catch (e) {
      printDebug(
        "Erreur lors de la création/mise à jour de la location tendance: $e",
      );
      return null;
    }
  }
}
