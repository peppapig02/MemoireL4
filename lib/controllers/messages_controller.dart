import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/messages_model.dart';

class MessagesController extends GetxController {
  var messages = MessagesModel().obs;

  var listMessages = <MessagesModel>[].obs;
  var listSearch = <MessagesModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Messages controller");
  }

  ///On recupère la liste des Messages
  Future<List<MessagesModel>?> getMessages() async {
    try {
      var res = await Setting.fMessages.get();

      var list =
          res.docs.map((e) {
            var r = MessagesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Messages :::$e");
      return null;
    }
  }

  Future<MessagesModel?> getOneMessages(String key) async {
    try {
      var e = await Setting.fMessages.doc(key).get();
      var r = MessagesModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Messages :::$e");
      return null;
    }
  }

  Future<String?> addMessages() async {
    try {
      var res = await Setting.fMessages.add(messages.value.toJson());
      messages.value = MessagesModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updateMessages({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fMessages.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listMessages.isNotEmpty) {
      var doc = await Setting.fMessages.doc(listMessages.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<MessagesModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fMessages.limit(1000);
    if (doc != null) {
      ref = Setting.fMessages.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<MessagesModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = MessagesModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return MessagesModel();
          }
        }).toList();
    listMessages.addAll(rs);
    listMessages.value = removeDub(listMessages);
    update();
    return rs;
  }

  List<MessagesModel> removeDub(List<MessagesModel> list) {
    Map<String, MessagesModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<MessagesModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fMessages.doc(val).get();
      var dt = MessagesModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <MessagesModel>[dt];

      listSearch.refresh();
      update();
      return <MessagesModel>[dt];
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
            ? Setting.fMessages
                .where(key, isGreaterThanOrEqualTo: val)
                .limit(100)
            : Setting.fMessages.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<MessagesModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = MessagesModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return MessagesModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountMessages() async {
    try {
      var res = await Setting.fMessages.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Messages $e");
      return null;
    }
  }

  Future<List<MessagesModel>?> getMessagesOfUser(String keyUser) async {
    try {
      //remplacer BDColumnNames.Messages_idOfUser par la propriété qui est le id de User dans Messages
      var res =
          await Setting.fMessages
              .where(BDColumnNames.Messages_sender, isEqualTo: keyUser)
              .get();

      var list =
          res.docs.map((e) {
            var r = MessagesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Messages of User :::$e");
      return null;
    }
  }

  Future<List<MessagesModel>?> getMessagesOfConversations(
    String keyConversations,
  ) async {
    try {
      //remplacer BDColumnNames.Messages_idOfConversations par la propriété qui est le id de Conversations dans Messages
      var res =
          await Setting.fMessages
              .where(
                BDColumnNames.Messages_id_conversation,
                isEqualTo: keyConversations,
              )
              .get();

      var list =
          res.docs.map((e) {
            var r = MessagesModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Messages of Conversations :::$e");
      return null;
    }
  }
}
