import 'package:botroad/bd/columns.dart';
import 'package:botroad/core/config/app_secrets.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/routes_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RoutesController extends GetxController {
  var routes = RoutesModel().obs;

  var listRoutes = <RoutesModel>[].obs;
  var listSearch = <RoutesModel>[].obs;
  String idSearch = "";
  PolylinePoints polylinePoints = PolylinePoints();

  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Routes controller");
  }

  ///On recupère la liste des Routes
  Future<List<RoutesModel>?> getRoutes() async {
    try {
      var res = await Setting.fRoutes.get();

      var list =
          res.docs.map((e) {
            var r = RoutesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Routes :::$e");
      return null;
    }
  }

  Future<RoutesModel?> getOneRoutes(String key) async {
    try {
      var e = await Setting.fRoutes.doc(key).get();
      var r = RoutesModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Routes :::$e");
      return null;
    }
  }

  Future<String?> addRoutes() async {
    try {
      var res = await Setting.fRoutes.add(routes.value.toJson());
      routes.value = RoutesModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateRoutes({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fRoutes.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listRoutes.isNotEmpty) {
      var doc = await Setting.fRoutes.doc(listRoutes.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<RoutesModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fRoutes.limit(1000);
    if (doc != null) {
      ref = Setting.fRoutes.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<RoutesModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = RoutesModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return RoutesModel();
          }
        }).toList();
    listRoutes.addAll(rs);
    listRoutes.value = removeDub(listRoutes);
    update();
    return rs;
  }

  List<RoutesModel> removeDub(List<RoutesModel> list) {
    Map<String, RoutesModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<RoutesModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fRoutes.doc(val).get();
      var dt = RoutesModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <RoutesModel>[dt];

      listSearch.refresh();
      update();
      return <RoutesModel>[dt];
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
            ? Setting.fRoutes.where(key, isGreaterThanOrEqualTo: val).limit(100)
            : Setting.fRoutes.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<RoutesModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = RoutesModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return RoutesModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountRoutes() async {
    try {
      var res = await Setting.fRoutes.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Routes $e");
      return null;
    }
  }

  Future<List<RoutesModel>?> getRoutesOfUser(String keyUser) async {
    try {
      //remplacer BDColumnNames.Routes_idOfUser par la propriété qui est le id de User dans Routes
      var res =
          await Setting.fRoutes
              .where(BDColumnNames.Routes_id_user, isEqualTo: keyUser)
              .get();

      var list =
          res.docs.map((e) {
            var r = RoutesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Routes of User :::$e");
      return null;
    }
  }

  Future<List<RoutesModel>?> getRoutesOfLocations(String keyLocations) async {
    try {
      //remplacer BDColumnNames.Routes_idOfLocations par la propriété qui est le id de Locations dans Routes
      var res =
          await Setting.fRoutes
              .where(BDColumnNames.Routes_origin_id, isEqualTo: keyLocations)
              .get();

      var list =
          res.docs.map((e) {
            var r = RoutesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Routes of Locations :::$e");
      return null;
    }
  }

  Future<RoutesModel?> createRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
    List<Map<String, dynamic>> waypoints,
    String? nom,
  ) async {
    try {
      // Créer les points de départ et d'arrivée
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: AppSecrets.googleMapsApiKey,

        request: PolylineRequest(
          wayPoints:
              waypoints.isEmpty
                  ? []
                  : waypoints
                      .map(
                        (wp) => PolylineWayPoint(
                          location: "${wp['latitude']},${wp['longitude']}",
                          stopOver: true,
                        ),
                      )
                      .toList(),
          origin: PointLatLng(originLat, originLng),
          destination: PointLatLng(destLat, destLng),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isEmpty) return null;

      // Créer le modèle de route
      final route = RoutesModel(
        nom:
            nom ?? "Route de ${originLat},${originLng} à ${destLat},${destLng}",
        // date_create: DateTime.now().toString(),
        id_user: Setting.userCtrl.user.value.key,
        points: result.points
            .map((point) => "${point.latitude},${point.longitude}")
            .join("|"),
        waypoints: waypoints,
      );

      // Sauvegarder la route dans la base de données
      routes.value = route;
      final key = await addRoutes();
      if (key != null) {
        route.key = key;
      }

      return route;
    } catch (e) {
      printDebug("error creating route: $e");
      return null;
    }
  }
}
