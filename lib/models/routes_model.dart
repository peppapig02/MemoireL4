import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoutesModel {
  String? key;
  String? id_user;
  String? origin_id; //location id
  String? destination_id; //location id
  List<Map<String, dynamic>>? waypoints;
  String? date_create;
  String? points;
  String? nom;

  RoutesModel({
    this.key,
    this.id_user,
    this.origin_id,
    this.destination_id,
    this.waypoints,
    this.date_create,
    this.points,
    this.nom,
  });

  RoutesModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Routes_key],
      id_user = map[BDColumnNames.Routes_id_user],
      origin_id = map[BDColumnNames.Routes_origin_id],
      destination_id = map[BDColumnNames.Routes_destination_id],
      waypoints =
          map[BDColumnNames.Routes_waypoints] != null
              ? map[BDColumnNames.Routes_waypoints]
                  .map((wp) => wp.cast<String, dynamic>())
                  .toList()
              : null,
      date_create =
          map[BDColumnNames.Routes_date_create] != null
              ? map[BDColumnNames.Routes_date_create] is String
                  ? map[BDColumnNames.Routes_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Routes_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null,
      points = map[BDColumnNames.Routes_points],
      nom = map[BDColumnNames.Routes_nom];

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Routes_key: key,
      BDColumnNames.Routes_id_user: id_user,
      BDColumnNames.Routes_origin_id: origin_id,
      BDColumnNames.Routes_destination_id: destination_id,
      BDColumnNames.Routes_waypoints: waypoints,
      BDColumnNames.Routes_date_create:
          date_create ?? FieldValue.serverTimestamp(),
      BDColumnNames.Routes_points: points,
      BDColumnNames.Routes_nom: nom,
    };
  }
}
