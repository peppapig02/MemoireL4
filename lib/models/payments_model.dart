import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentsModel {
  String? key;
  String? id_user;
  String? method;
  String? amount;
  String? credits_added;
  String? status;
  String? reference;
  String? date_create;
  String? date_statut;

  PaymentsModel({
    this.key,
    this.id_user,
    this.method,
    this.amount,
    this.credits_added,
    this.status,
    this.reference,
    this.date_create,
    this.date_statut,
  });

  PaymentsModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Payments_key],
      id_user = map[BDColumnNames.Payments_id_user],
      method = map[BDColumnNames.Payments_method],
      amount = Setting.encrypt.decrypt(
        map[BDColumnNames.Payments_amount] ?? "",
      ),
      credits_added = Setting.encrypt.decrypt(
        map[BDColumnNames.Payments_credits_added] ?? "",
      ),
      status = map[BDColumnNames.Payments_status],
      reference = map[BDColumnNames.Payments_reference],
      date_create =
          map[BDColumnNames.Payments_date_create] != null
              ? map[BDColumnNames.Payments_date_create] is String
                  ? map[BDColumnNames.Payments_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Payments_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_statut =
          map[BDColumnNames.Payments_date_statut] != null
              ? map[BDColumnNames.Payments_date_statut] is String
                  ? map[BDColumnNames.Payments_date_statut]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Payments_date_statut]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null;

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Payments_key: key,
      BDColumnNames.Payments_id_user: id_user,
      BDColumnNames.Payments_method: method,
      BDColumnNames.Payments_amount: Setting.encrypt.encrypt(amount ?? ""),
      BDColumnNames.Payments_credits_added: Setting.encrypt.encrypt(
        credits_added ?? "",
      ),
      BDColumnNames.Payments_status: status,
      BDColumnNames.Payments_reference: reference,
      BDColumnNames.Payments_date_create:
          date_create ?? FieldValue.serverTimestamp(),
      BDColumnNames.Payments_date_statut:
          date_statut ?? FieldValue.serverTimestamp(),
    };
  }
}
