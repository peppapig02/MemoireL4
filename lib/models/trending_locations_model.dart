import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Trending_locationsModel {
  String? key;
  String? id_location;
  int? count;
  String? period;
  String? date_create;
  String? id_user;

  Trending_locationsModel({
    this.key,
    this.id_location,
    this.count,
    this.period,
    this.date_create,
    this.id_user,
  });

  Trending_locationsModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Trending_locations_key],
      id_location = map[BDColumnNames.Trending_locations_id_location],
      count = map[BDColumnNames.Trending_locations_count],
      period =
          map[BDColumnNames.Trending_locations_period] != null
              ? map[BDColumnNames.Trending_locations_period] is String
                  ? map[BDColumnNames.Trending_locations_period]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Trending_locations_period]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_create =
          map[BDColumnNames.Trending_locations_date_create] != null
              ? map[BDColumnNames.Trending_locations_date_create] is String
                  ? map[BDColumnNames.Trending_locations_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Trending_locations_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null,
      id_user = map[BDColumnNames.Trending_locations_id_user];

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Trending_locations_key: key,
      BDColumnNames.Trending_locations_id_location: id_location,
      BDColumnNames.Trending_locations_count: count,
      BDColumnNames.Trending_locations_period:
          period ?? FieldValue.serverTimestamp(),
      BDColumnNames.Trending_locations_date_create:
          date_create ?? FieldValue.serverTimestamp(),
      BDColumnNames.Trending_locations_id_user: id_user,
    };
  }
}
