import 'package:botroad/bd/columns.dart';
import 'package:botroad/core/config/app_secrets.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/locations_model.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class LocationsController extends GetxController {
  var locations = LocationsModel().obs;

  var listLocations = <LocationsModel>[].obs;
  var listSearch = <LocationsModel>[].obs;
  String idSearch = "";
  FlutterGooglePlacesSdk? placesSdk;

  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Locations controller");
    _initPlacesSdk();
  }

  void _initPlacesSdk() {
    placesSdk = FlutterGooglePlacesSdk(AppSecrets.googleMapsApiKey);
  }

  ///On recupère la liste des Locations
  Future<List<LocationsModel>?> getLocations() async {
    try {
      var res = await Setting.fLocations.get();

      var list =
          res.docs.map((e) {
            var r = LocationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Locations :::$e");
      return null;
    }
  }

  Future<LocationsModel?> getOneLocations(String key) async {
    try {
      var e = await Setting.fLocations.doc(key).get();
      var r = LocationsModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Locations :::$e");
      return null;
    }
  }

  Future<String?> addLocations() async {
    try {
      var res = await Setting.fLocations.add(locations.value.toJson());
      locations.value = LocationsModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateLocations({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fLocations.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listLocations.isNotEmpty) {
      var doc = await Setting.fLocations.doc(listLocations.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<LocationsModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fLocations.limit(1000);
    if (doc != null) {
      ref = Setting.fLocations.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<LocationsModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = LocationsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return LocationsModel();
          }
        }).toList();
    listLocations.addAll(rs);
    listLocations.value = removeDub(listLocations);
    update();
    return rs;
  }

  List<LocationsModel> removeDub(List<LocationsModel> list) {
    Map<String, LocationsModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<LocationsModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fLocations.doc(val).get();
      var dt = LocationsModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <LocationsModel>[dt];

      listSearch.refresh();
      update();
      return <LocationsModel>[dt];
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
            ? Setting.fLocations
                .where(key, isGreaterThanOrEqualTo: val)
                .limit(100)
            : Setting.fLocations.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<LocationsModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = LocationsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return LocationsModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<List<LocationsModel>?> searchLocationByLat(
    double lat,
    double long,
  ) async {
    try {
      var ref =
          await Setting.fLocations
              .where(BDColumnNames.Locations_latitude, isEqualTo: lat)
              .where(BDColumnNames.Locations_longitude, isEqualTo: long)
              .limit(1)
              .get();
      var list =
          ref.docs.map((e) {
            var r = LocationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error searchLocationByLat $e");
      return null;
    }
  }

  Future<int?> getCountLocations() async {
    try {
      var res = await Setting.fLocations.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Locations $e");
      return null;
    }
  }

  Future<List<LocationsModel>?> getLocationsOfUser(String keyUser) async {
    try {
      //remplacer BDColumnNames.Locations_idOfUser par la propriété qui est le id de User dans Locations
      var res =
          await Setting.fLocations
              .where(BDColumnNames.Locations_id_user, isEqualTo: keyUser)
              .get();

      var list =
          res.docs.map((e) {
            var r = LocationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Locations of User :::$e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> searchPlace(
    String query, {
    double? biasLatitude,
    double? biasLongitude,
  }) async {
    try {
      if (placesSdk == null) {
        _initPlacesSdk();
        if (placesSdk == null) return null;
      }

      // Rechercher le lieu
      final predictions = await placesSdk!.findAutocompletePredictions(
        query,
        origin:
            biasLatitude != null && biasLongitude != null
                ? LatLng(lat: biasLatitude, lng: biasLongitude)
                : null,
        locationBias:
            biasLatitude != null && biasLongitude != null
                ? _buildLocationBias(biasLatitude, biasLongitude)
                : null,
        countries: ['CD'], // Limiter à la République Démocratique du Congo
      );

      if (predictions.predictions.isEmpty) return null;

      // Obtenir les détails du premier résultat
      final rankedPredictions =
          predictions.predictions.toList()..sort((a, b) {
            final aDistance = a.distanceMeters ?? 1 << 30;
            final bDistance = b.distanceMeters ?? 1 << 30;
            return aDistance.compareTo(bDistance);
          });
      final place = rankedPredictions.first;
      final details = await placesSdk!.fetchPlace(
        place.placeId,
        fields: [
          PlaceField.Name,
          PlaceField.Address,
          PlaceField.Location,
          PlaceField.Types,
        ],
      );

      final placeName =
          details.place?.name?.trim().isNotEmpty == true
              ? details.place!.name!
              : place.primaryText.trim().isNotEmpty
              ? place.primaryText
              : (details.place?.address?.trim().isNotEmpty == true
                  ? details.place!.address!
                  : query.trim());
      printDebug(
        "details : ${details.place?.address} $placeName ${details.place?.latLng?.lat} ${details.place?.latLng?.lng}",
      );
      // Créer un modèle de lieu
      final location = LocationsModel(
        nom: placeName,
        place_id: place.placeId,
        latitude: details.place?.latLng?.lat,
        id_user: Setting.userCtrl.user.value.key,
        longitude: details.place?.latLng?.lng,
      );

      // Sauvegarder le lieu dans la base de données
      locations.value = location;
      var list = await searchLocationByLat(
        details.place?.latLng?.lat ?? 0,
        details.place?.latLng?.lng ?? 0,
      );
      if (list != null && list.isEmpty) {
        final key = await addLocations();
        if (key != null) {
          location.key = key;
        }
      } else {
        if (list?.isNotEmpty ?? false) {
          Setting.trending_locationsCtrl.createOrUpdateTrendingLocation(
            list!.first.key ?? "",
          );
        }
      }

      return {
        'latitude': details.place?.latLng?.lat,
        'longitude': details.place?.latLng?.lng,
        'name': placeName,
        'place_id': place.placeId,
      };
    } catch (e) {
      printDebug("error searching place: $e");
      return null;
    }
  }

  LatLngBounds _buildLocationBias(double latitude, double longitude) {
    const delta = 0.06;
    return LatLngBounds(
      southwest: LatLng(lat: latitude - delta, lng: longitude - delta),
      northeast: LatLng(lat: latitude + delta, lng: longitude + delta),
    );
  }
}
