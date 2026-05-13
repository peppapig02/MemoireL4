import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/payments_model.dart';

class PaymentsController extends GetxController {
  var payments = PaymentsModel().obs;

  var listPayments = <PaymentsModel>[].obs;
  var listSearch = <PaymentsModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing Payments controller");
  }

  ///On recupère la liste des Payments
  Future<List<PaymentsModel>?> getPayments() async {
    try {
      var res = await Setting.fPayments.get();

      var list =
          res.docs.map((e) {
            var r = PaymentsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Payments :::$e");
      return null;
    }
  }

  Future<PaymentsModel?> getOnePayments(String key) async {
    try {
      var e = await Setting.fPayments.doc(key).get();
      var r = PaymentsModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one Payments :::$e");
      return null;
    }
  }

  Future<String?> addPayments() async {
    try {
      var res = await Setting.fPayments.add(payments.value.toJson());
      payments.value = PaymentsModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool?> updatePayments({
    required Map<String, dynamic> map,
    required String key,
  }) async {
    try {
      await Setting.fPayments.doc(key).update(map);
      return true;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listPayments.isNotEmpty) {
      var doc = await Setting.fPayments.doc(listPayments.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<PaymentsModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fPayments.limit(1000);
    if (doc != null) {
      ref = Setting.fPayments.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<PaymentsModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = PaymentsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return PaymentsModel();
          }
        }).toList();
    listPayments.addAll(rs);
    listPayments.value = removeDub(listPayments);
    update();
    return rs;
  }

  List<PaymentsModel> removeDub(List<PaymentsModel> list) {
    Map<String, PaymentsModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<PaymentsModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fPayments.doc(val).get();
      var dt = PaymentsModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <PaymentsModel>[dt];

      listSearch.refresh();
      update();
      return <PaymentsModel>[dt];
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
            ? Setting.fPayments
                .where(key, isGreaterThanOrEqualTo: val)
                .limit(100)
            : Setting.fPayments.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<PaymentsModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = PaymentsModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return PaymentsModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountPayments() async {
    try {
      var res = await Setting.fPayments.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count Payments $e");
      return null;
    }
  }

  Future<List<PaymentsModel>?> getPaymentsOfUser(String keyUser) async {
    try {
      //remplacer BDColumnNames.Payments_idOfUser par la propriété qui est le id de User dans Payments
      var res =
          await Setting.fPayments
              .where(BDColumnNames.Payments_id_user, isEqualTo: keyUser)
              .get();

      var list =
          res.docs.map((e) {
            var r = PaymentsModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get Payments of User :::$e");
      return null;
    }
  }
}
