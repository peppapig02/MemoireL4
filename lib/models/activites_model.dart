import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivitesModel {
  String? key;
  String? type;
  String? id_type;
  String? id_user;
  String? libelle;
  Map<String, dynamic>? data_before;
  Map<String, dynamic>? data_after;
  String? date_create;

  ActivitesModel({
    this.key,
    this.type,
    this.id_type,
    this.id_user,
    this.libelle,
    this.data_before,
    this.data_after,
    this.date_create,
  });

  ActivitesModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Activites_key],
      type = map[BDColumnNames.Activites_type],
      id_type = map[BDColumnNames.Activites_id_type],
      id_user = map[BDColumnNames.Activites_id_user],
      libelle = map[BDColumnNames.Activites_libelle],
      data_before = map[BDColumnNames.Activites_data_before],
      data_after = map[BDColumnNames.Activites_data_after],
      date_create =
          map[BDColumnNames.Activites_date_create] != null
              ? map[BDColumnNames.Activites_date_create] is String
                  ? map[BDColumnNames.Activites_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Activites_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null;

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Activites_key: key,
      BDColumnNames.Activites_type: type,
      BDColumnNames.Activites_id_type: id_type,
      BDColumnNames.Activites_id_user: id_user,
      BDColumnNames.Activites_libelle: libelle,
      BDColumnNames.Activites_data_before: data_before,
      BDColumnNames.Activites_data_after: data_after,
      BDColumnNames.Activites_date_create:
          date_create ?? FieldValue.serverTimestamp(),
    };
  }
}
