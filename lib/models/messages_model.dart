import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesModel {
  String? key;
  String? id_conversation;
  String? sender; //bot ou user
  String? content;
  String? date_create;

  MessagesModel({
    this.key,
    this.id_conversation,
    this.sender,
    this.content,
    this.date_create,
  });

  MessagesModel.fromJson(dynamic map)
    : key = map[BDColumnNames.Messages_key],
      id_conversation = map[BDColumnNames.Messages_id_conversation],
      sender = map[BDColumnNames.Messages_sender],
      content = map[BDColumnNames.Messages_content],
      date_create =
          map[BDColumnNames.Messages_date_create] != null
              ? map[BDColumnNames.Messages_date_create] is String
                  ? map[BDColumnNames.Messages_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.Messages_date_create]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null;

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.Messages_key: key,
      BDColumnNames.Messages_id_conversation: id_conversation,
      BDColumnNames.Messages_sender: sender,
      BDColumnNames.Messages_content: content,
      BDColumnNames.Messages_date_create:
          date_create ?? FieldValue.serverTimestamp(),
    };
  }
}
