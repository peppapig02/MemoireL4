import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/conversations_model.dart';

class ConversationsController extends GetxController {
  var conversations = ConversationsModel().obs;

  var listConversations = <ConversationsModel>[].obs;
  var listSearch = <ConversationsModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Conversations controller");
  }

  ///On recupère la liste des Conversations
  Future<List<ConversationsModel>?> getConversations() async {
    try {
      var res = await Setting.fConversations.get();

      var list =
          res.docs.map((e) {
            var r = ConversationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Conversations :::$e");
      return null;
    }
  }

  Future<ConversationsModel?> getOneConversations(String key) async {
    try {
      var e = await Setting.fConversations.doc(key).get();
      var r = ConversationsModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Conversations :::$e");
      return null;
    }
  }

  Future<String?> addConversations() async {
    try {
      var res = await Setting.fConversations.add(conversations.value.toJson());
      conversations.value = ConversationsModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateConversations({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fConversations.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listConversations.isNotEmpty) {
      var doc =
          await Setting.fConversations.doc(listConversations.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<ConversationsModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fConversations.limit(1000);
    if (doc != null) {
      ref = Setting.fConversations.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<ConversationsModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = ConversationsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return ConversationsModel();
          }
        }).toList();
    listConversations.addAll(rs);
    listConversations.value = removeDub(listConversations);
    update();
    return rs;
  }

  List<ConversationsModel> removeDub(List<ConversationsModel> list) {
    Map<String, ConversationsModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<ConversationsModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fConversations.doc(val).get();
      var dt = ConversationsModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <ConversationsModel>[dt];

      listSearch.refresh();
      update();
      return <ConversationsModel>[dt];
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
            ? Setting.fConversations
                .where(key, isGreaterThanOrEqualTo: val)
                .limit(100)
            : Setting.fConversations.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<ConversationsModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = ConversationsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return ConversationsModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountConversations() async {
    try {
      var res = await Setting.fConversations.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Conversations $e");
      return null;
    }
  }

  Future<List<ConversationsModel>?> getConversationsOfUser(
    String keyUser, {
    int? limit,
    ConversationsModel? startAfter,
  }) async {
    try {
      var query = Setting.fConversations
          .where(BDColumnNames.Conversations_id_user, isEqualTo: keyUser)
          .orderBy(BDColumnNames.Conversations_date_create, descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (startAfter != null && startAfter.key != null) {
        final doc = await Setting.fConversations.doc(startAfter.key).get();
        query = query.startAfterDocument(doc);
      }

      var res = await query.get();

      var list =
          res.docs.map((e) {
            var r = ConversationsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Conversations of User :::$e");
      return null;
    }
  }

  /// Supprime une conversation et tous ses messages associés.
  Future<bool> deleteConversation(String key) async {
    try {
      // Delete all messages in the conversation first
      final msgs = await Setting.fMessages
          .where(BDColumnNames.Messages_id_conversation, isEqualTo: key)
          .get();
      final batch = Setting.firestore.batch();
      for (final doc in msgs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(Setting.fConversations.doc(key));
      await batch.commit();

      listConversations.removeWhere((c) => c.key == key);
      listConversations.refresh();
      update();
      return true;
    } catch (e) {
      printDebug("error delete conversation :::$e");
      return false;
    }
  }
}
