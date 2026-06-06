import 'dart:async';

import 'package:botroad/bd/columns.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserController extends GetxController {
  var user = UserModel().obs;

  var listUser = <UserModel>[].obs;
  var listSearch = <UserModel>[].obs;
  String idSearch = "";
  @override
  void onInit() {
    super.onInit();
    printDebug("Initializing User controller");
  }

  ///On recupère la liste des User
  Future<List<UserModel>?> getUser() async {
    try {
      var res = await Setting.fUser.get();

      var list =
          res.docs.map((e) {
            var r = UserModel.fromJson(e.data());
            r.key = e.reference.id;
            return r;
          }).toList();
      return list;
    } catch (e) {
      printDebug("error get User :::$e");
      return null;
    }
  }

  Future<UserModel?> getOneUser(String key) async {
    try {
      var e = await Setting.fUser.doc(key).get();
      var r = UserModel.fromJson(e.data());
      r.key = e.reference.id;
      return r;
    } catch (e) {
      printDebug("error get one User :::$e");
      return null;
    }
  }

  Future<String?> addUser() async {
    try {
      var res = await Setting.fUser.add(user.value.toJson());
      user.value = UserModel();
      return res.id;
    } catch (e) {
      return null;
    }
  }

  callNextUsersList() async {
    if (listUser.isNotEmpty) {
      var doc = await Setting.fUser.doc(listUser.last.key).get();
      getUsersStepByStep(doc);
    } else {
      getUsersStepByStep(null);
    }
  }

  Future<List<UserModel>> getUsersStepByStep(
    DocumentSnapshot<Object?>? doc,
  ) async {
    var ref = Setting.fUser.limit(1000);
    if (doc != null) {
      ref = Setting.fUser.startAtDocument(doc).limit(1000);
    }
    var list = await ref.get();
    var rs =
        list.docs.map<UserModel>((e) {
          var map = e.data() as Map<String, dynamic>;

          try {
            var us = UserModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return UserModel();
          }
        }).toList();
    listUser.addAll(rs);
    listUser.value = removeDub(listUser);
    update();
    return rs;
  }

  List<UserModel> removeDub(List<UserModel> list) {
    Map<String, UserModel> map = {};
    for (var e in list) {
      map.addAll({e.key ?? "": e});
    }
    return map.values.toList();
  }

  Future<List<UserModel>> getSearchByFiltre(
    String key,
    dynamic val, [
    bool? exact,
  ]) async {
    if (key == "key") {
      var d = await Setting.fUser.doc(val).get();
      var dt = UserModel.fromJson(d.data());
      dt.key = d.reference.id;

      listSearch.value = <UserModel>[dt];

      listSearch.refresh();
      update();
      return <UserModel>[dt];
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
            ? Setting.fUser.where(key, isGreaterThanOrEqualTo: val).limit(100)
            : Setting.fUser.where(key, isEqualTo: val).limit(100);
    var list = await ref.get();

    var rs =
        list.docs.map<UserModel>((e) {
          var map = e.data() as Map<String, dynamic>;
          try {
            var us = UserModel.fromJson(map);
            us.key = e.reference.id;
            return us;
          } catch (e) {
            printDebug("error parsing $e");
            return UserModel();
          }
        }).toList();

    listSearch.value = rs;

    listSearch.refresh();
    update();
    return rs;
  }

  Future<int?> getCountUser() async {
    try {
      var res = await Setting.fUser.count().get();
      return res.count;
    } catch (e) {
      printDebug("error count User $e");
      return null;
    }
  }

  @override
  void onClose() {
    if (timer != null) timer!.cancel();
    if (conStream != null) conStream!.cancel();
  }

  StreamSubscription? conStream;
  Timer? timer;
  var loading = false.obs;
  bool on = false;
  openStreams() {
    conStream = Setting.fUser.doc(user.value.key).snapshots().listen((res) {
      if (res.data() == null) return;
      user.value = UserModel.fromJson(res.data() as Map<String, dynamic>);
      user.value.key = res.reference.id;
      saveUserLocal();
    });
    timer = Timer.periodic(const Duration(seconds: 30), (t) async {
      if (!on) {
        on = true;
        if (user.value.key != null) {
          await updateUser({
            BDColumnNames.User_date_connexion: FieldValue.serverTimestamp(),
          });
        }

        on = false;
      }
    });

    if (user.value.key != null) {
      updateUser({
        BDColumnNames.User_date_connexion: FieldValue.serverTimestamp(),
      });
    }
  }

  ///Méthode pour se déconnecter
  Future<bool> deconnectUser() async {
    try {
      var res = await Get.defaultDialog(
        title: "Déconnexion",
        middleText: "Voulez-vous vraiment vous déconnecter?",
        textCancel: "Annuler",
        textConfirm: "Oui",
        onConfirm: () {
          Get.back(result: true);
        },
      );
      if (res == true) {
        await Setting.auth!.signOut();
        Setting.user = null;
        await GetStorage(Setting.storageName).erase();
        SystemNavigator.pop();
      }
    } catch (e) {
      printDebug("error $e");

      return false;
    }

    return true;
  }

  String messageErreur = "";

  Future<bool> signin(String email, String pwd) async {
    loading.value = true;
    loading.refresh();

    try {
      var user = await Setting.auth!.signInWithEmailAndPassword(
        email: email,
        password: pwd,
      );
      Setting.user = user.user;
      var res = await getOneUser(user.user!.uid);

      openStreams();
      this.user.value = res!;

      saveUserLocal();

      loading.value = false;
      loading.refresh();
      return true;
    } catch (e) {
      if (e.toString().contains("invalid-email")) {
        messageErreur = "Email incorrect";
        printDebug("Email incorrect");
      } else if (e.toString().contains("wrong-password")) {
        printDebug("Mot de passe incorrect");
        messageErreur = "Mot de passe incorrect";
      } else if (e.toString().contains("not-found")) {
        printDebug("utiliateur non trouvé");
        messageErreur = "Cet email ne correspond à aucun utilisateur";
      } else {
        messageErreur = "Erreur interne";
        printDebug("error::`$e");
      }
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    loading.value = true;
    loading.refresh();

    try {
      await Setting.auth!.sendPasswordResetEmail(email: email.trim());
      loading.value = false;
      loading.refresh();
      return true;
    } catch (e) {
      if (e.toString().contains("invalid-email")) {
        messageErreur = "Email incorrect";
        printDebug("Email incorrect");
      } else if (e.toString().contains("user-not-found") ||
          e.toString().contains("not-found")) {
        messageErreur = "Cet email ne correspond a aucun utilisateur";
        printDebug("Utilisateur non trouve");
      } else {
        messageErreur = "Erreur lors de l'envoi du lien";
        printDebug("error reset password::$e");
      }
      loading.value = false;
      loading.refresh();
      return false;
    }
  }

  Future<bool> createUser() async {
    try {
      loading.value = true;
      loading.refresh();
      var r = await Setting.auth!.createUserWithEmailAndPassword(
        email: user.value.email ?? "",
        password: user.value.password ?? "",
      );
      Setting.user = r.user;
      await Setting.fUser.doc(r.user!.uid).set(user.value.toJson());
      var res2 = await Setting.fUser.doc(r.user!.uid).get();
      user.value = UserModel.fromJson(res2.data() as Map<String, dynamic>);
      user.value.key = res2.reference.id;

      saveUserLocal();
      loading.value = false;
      loading.refresh();
      return true;
    } catch (err) {
      if (err.toString().contains("invalid-email")) {
        messageErreur = "Email incorrect";
        printDebug("Email incorrect");
      } else if (err.toString().contains("weak-password")) {
        messageErreur = "Mot de passe trop faible";
        printDebug("Mot de passe trop faible");
      } else if (err.toString().contains("already-in-use")) {
        messageErreur = "Email deja utilisé";
        printDebug("Email deja utilisé");
      } else {
        messageErreur = "Erreur interne";
        printDebug("error::$err");
      }
    }
    loading.value = false;
    loading.refresh();
    return false;
  }

  ///Connexion avec Google
  Future<bool> signInWithGoogle() async {
    loading.value = true;
    loading.refresh();

    try {
      // Déclencher le flux d'authentification
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        messageErreur = "Connexion Google annulée";
        loading.value = false;
        loading.refresh();
        return false;
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Créer un nouveau credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter avec Firebase
      final userCredential = await Setting.auth!.signInWithCredential(
        credential,
      );
      Setting.user = userCredential.user;

      // Vérifier si l'utilisateur existe déjà
      var res = await getOneUser(userCredential.user!.uid);

      if (res == null) {
        // Créer un nouvel utilisateur si n'existe pas
        user.value = UserModel(
          key: userCredential.user!.uid,
          email: userCredential.user!.email,
          google_id: userCredential.user!.uid,
          nom: userCredential.user!.displayName,
          is_active: true,
          is_admin: false,
        );

        await Setting.fUser
            .doc(userCredential.user!.uid)
            .set(user.value.toJson());
        res = await getOneUser(userCredential.user!.uid);
      }

      if (res != null) {
        openStreams();
        user.value = res;
        saveUserLocal();
      }

      loading.value = false;
      loading.refresh();
      return true;
    } catch (e) {
      messageErreur = "Erreur lors de la connexion avec Google";
      printDebug("error signInWithGoogle::$e");
      loading.value = false;
      loading.refresh();
      return false;
    }
  }

  Future<bool> updateUser(Map<String, dynamic> map, [String? key]) async {
    try {
      if ((key ?? (user.value.key ?? "")).isEmpty) return false;
      await Setting.fUser.doc(key ?? user.value.key).update(map);
      if (key == null || key.trim() == user.value.key!.trim()) {
        var res = await getOneUser(user.value.key!);
        user.value = res!;
      }
    } catch (e) {
      messageErreur = "Erreur interne";
      printDebug("error:::$e");
      return false;
    }
    if (key == null || key.trim() == user.value.key!.trim()) {
      saveUserLocal(map: map);
    }
    return true;
  }

  Future<bool> saveUserLocal({Map? map}) async {
    var storage = GetStorage(Setting.storageName);

    if (map != null) {
      map.forEach((key, value) {
        if (value is! FieldValue) {
          storage.write(
            key,
            value is Timestamp
                ? DateTime.fromMillisecondsSinceEpoch(
                  value.millisecondsSinceEpoch,
                ).toString()
                : value,
          );
        }
      });
    } else {
      user.value.toJson().forEach((key, value) {
        if (value is! FieldValue) {
          storage.write(
            key,
            value is Timestamp
                ? DateTime.fromMillisecondsSinceEpoch(
                  value.millisecondsSinceEpoch,
                ).toString()
                : value,
          );
        }
      });
      storage.write("key", user.value.key);
    }

    return true;
  }

  bool getUserLocal() {
    var storage = GetStorage(Setting.storageName);
    if (storage.hasData("key")) {
      Map<String, dynamic> userMap = {};
      storage.getKeys().forEach((e) {
        userMap.addAll({e: storage.read(e)});
      });
      user.value = UserModel.fromJson(userMap);
      user.value.key = storage.read("key");
      printDebug("user value ${user.value.toJson()}");

      return true;
    }

    return false;
  }
}
