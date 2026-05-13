import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationsModel {
  String? key;
  String? nom;
  String? place_id;
  String? category;
  int? popularity_score;
  double? latitude;
  double? longitude;
  String? date_create;
  String? id_user;

  LocationsModel({
    this.key,
    this.nom,
    this.place_id,
    this.category,
    this.popularity_score,
    this.latitude,
    this.longitude,
    this.date_create,
    this.id_user,
  });

  LocationsModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Locations_key],
      nom = map[BDColumnNames.Locations_nom],
      place_id = map[BDColumnNames.Locations_place_id],
      category = map[BDColumnNames.Locations_category],
      popularity_score = map[BDColumnNames.Locations_popularity_score],
      latitude = map[BDColumnNames.Locations_latitude],
      longitude = map[BDColumnNames.Locations_longitude],
      date_create =
          map[BDColumnNames.Locations_date_create] != null
              ? map[BDColumnNames.Locations_date_create] is String
                  ? map[BDColumnNames.Locations_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Locations_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null,
      id_user = map[BDColumnNames.Locations_id_user];

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Locations_key: key,
      BDColumnNames.Locations_nom: nom,
      BDColumnNames.Locations_place_id: place_id,
      BDColumnNames.Locations_category: category,
      BDColumnNames.Locations_popularity_score: popularity_score,
      BDColumnNames.Locations_latitude: latitude,
      BDColumnNames.Locations_longitude: longitude,
      BDColumnNames.Locations_date_create:
          date_create ?? FieldValue.serverTimestamp(),
      BDColumnNames.Locations_id_user: id_user,
    };
  }
}
