import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationsModel {
  String? key;
  String? id_user;
  String? libelle;
  String? date_create;

  ConversationsModel({this.key, this.id_user, this.libelle, this.date_create});

  ConversationsModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Conversations_key],
      id_user = map[BDColumnNames.Conversations_id_user],
      libelle = map[BDColumnNames.Conversations_libelle],
      date_create =
          map[BDColumnNames.Conversations_date_create] != null
              ? map[BDColumnNames.Conversations_date_create] is String
                  ? map[BDColumnNames.Conversations_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Conversations_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null;

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Conversations_key: key,
      BDColumnNames.Conversations_id_user: id_user,
      BDColumnNames.Conversations_libelle: libelle,
      BDColumnNames.Conversations_date_create:
          date_create ?? FieldValue.serverTimestamp(),
    };
  }
}
