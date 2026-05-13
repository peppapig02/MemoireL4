import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdsModel {
  String? key;
  String? title;
  String? description;
  String? target_location;
  String? date_create;
  String? date_active;
  String? date_begin;
  String? date_end;
  String? amount;
  bool? is_active;
  String? id_user_admin;

  AdsModel({
    this.key,
    this.title,
    this.description,
    this.target_location,
    this.date_create,
    this.date_active,
    this.date_begin,
    this.date_end,
    this.amount,
    this.is_active,
    this.id_user_admin,
  });

  AdsModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Ads_key],
      title = map[BDColumnNames.Ads_title],
      description = map[BDColumnNames.Ads_description],
      target_location = map[BDColumnNames.Ads_target_location],
      date_create =
          map[BDColumnNames.Ads_date_create] != null
              ? map[BDColumnNames.Ads_date_create] is String
                  ? map[BDColumnNames.Ads_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Ads_date_create].millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_active =
          map[BDColumnNames.Ads_date_active] != null
              ? map[BDColumnNames.Ads_date_active] is String
                  ? map[BDColumnNames.Ads_date_active]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Ads_date_active].millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_begin =
          map[BDColumnNames.Ads_date_begin] != null
              ? map[BDColumnNames.Ads_date_begin] is String
                  ? map[BDColumnNames.Ads_date_begin]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Ads_date_begin].millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_end =
          map[BDColumnNames.Ads_date_end] != null
              ? map[BDColumnNames.Ads_date_end] is String
                  ? map[BDColumnNames.Ads_date_end]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Ads_date_end].millisecondsSinceEpoch,
                  ).toString()
              : null,
      amount = map[BDColumnNames.Ads_amount],
      is_active = map[BDColumnNames.Ads_is_active],
      id_user_admin = map[BDColumnNames.Ads_id_user_admin];

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Ads_key: key,
      BDColumnNames.Ads_title: title,
      BDColumnNames.Ads_description: description,
      BDColumnNames.Ads_target_location: target_location,
      BDColumnNames.Ads_date_create:
          date_create ?? FieldValue.serverTimestamp(),
      BDColumnNames.Ads_date_active:
          date_active ?? FieldValue.serverTimestamp(),
      BDColumnNames.Ads_date_begin: date_begin ?? FieldValue.serverTimestamp(),
      BDColumnNames.Ads_date_end: date_end ?? FieldValue.serverTimestamp(),
      BDColumnNames.Ads_amount: amount,
      BDColumnNames.Ads_is_active: is_active,
      BDColumnNames.Ads_id_user_admin: id_user_admin,
    };
  }
}
