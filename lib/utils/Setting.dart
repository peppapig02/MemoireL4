import 'package:botroad/controllers/activites_controller.dart';
import 'package:botroad/controllers/ads_controller.dart';
import 'package:botroad/controllers/conversations_controller.dart';
import 'package:botroad/controllers/home_controller.dart';
import 'package:botroad/controllers/locations_controller.dart';
import 'package:botroad/controllers/messages_controller.dart';
import 'package:botroad/controllers/payments_controller.dart';
import 'package:botroad/controllers/routes_controller.dart';
import 'package:botroad/controllers/trending_locations_controller.dart';
import 'package:botroad/controllers/user_controller.dart';
import 'package:botroad/firebase_options.dart';
import 'package:botroad/utils/crypt/cryptService.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void printDebug(String text) {
  if (kDebugMode) {
    print(text);
  }
}

class Setting {
  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static FirebaseAuth? auth;
  static User? user;
  static String version = "1.0";
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static CollectionReference fMiseAjour = firestore.collection("MiseAjour");

  static Future initUser() async {
    WidgetsFlutterBinding.ensureInitialized();
    printDebug("getting");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).whenComplete(() async {
      auth = FirebaseAuth.instance;
      user = auth!.currentUser;
    });

    await GetStorage.init(storageName);
    printDebug("leaving");
  }

  static CryptDecrypt encrypt = CryptDecrypt();
  static String storageName = "botroad";
  static Future<bool> openUrl(String url, {bool newWindow = false}) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      return await launchUrl(
        Uri.parse(url),
        mode:
            newWindow
                ? LaunchMode.externalApplication
                : LaunchMode.platformDefault,
      );
    } else {
      print("Could not launch $url");
      return false;
    }
  }

  static void showMessage(
    String title,
    String msg, [
    Color color = Colors.white,
  ]) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      colorText: color,
    );
  }

  static Future showDialog(String title, String msg) async {
    await Get.defaultDialog(title: title, middleText: msg, textCancel: "Ok");
  }

  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  static CollectionReference fUser = firestore.collection("User");
  static UserController get userCtrl {
    try {
      return Get.find<UserController>();
    } catch (e) {
      return Get.put(UserController());
    }
  }

  static CollectionReference fConversations = firestore.collection(
    "Conversations",
  );
  static ConversationsController get conversationsCtrl {
    try {
      return Get.find<ConversationsController>();
    } catch (e) {
      return Get.put(ConversationsController());
    }
  }

  static CollectionReference fMessages = firestore.collection("Messages");
  static MessagesController get messagesCtrl {
    try {
      return Get.find<MessagesController>();
    } catch (e) {
      return Get.put(MessagesController());
    }
  }

  static CollectionReference fLocations = firestore.collection("Locations");
  static LocationsController get locationsCtrl {
    try {
      return Get.find<LocationsController>();
    } catch (e) {
      return Get.put(LocationsController());
    }
  }

  static CollectionReference fRoutes = firestore.collection("Routes");
  static RoutesController get routesCtrl {
    try {
      return Get.find<RoutesController>();
    } catch (e) {
      return Get.put(RoutesController());
    }
  }

  static CollectionReference<Map<String, dynamic>> fTripHistory = firestore
      .collection("TripHistory");
  static CollectionReference<Map<String, dynamic>> fRoadReports = firestore
      .collection("RoadReports");

  static CollectionReference fPayments = firestore.collection("Payments");
  static PaymentsController get paymentsCtrl {
    try {
      return Get.find<PaymentsController>();
    } catch (e) {
      return Get.put(PaymentsController());
    }
  }

  static CollectionReference fTrending_locations = firestore.collection(
    "Trending_locations",
  );
  static Trending_locationsController get trending_locationsCtrl {
    try {
      return Get.find<Trending_locationsController>();
    } catch (e) {
      return Get.put(Trending_locationsController());
    }
  }

  static CollectionReference fAds = firestore.collection("Ads");
  static AdsController get adsCtrl {
    try {
      return Get.find<AdsController>();
    } catch (e) {
      return Get.put(AdsController());
    }
  }

  static CollectionReference fActivites = firestore.collection("Activites");
  static ActivitesController get activitesCtrl {
    try {
      return Get.find<ActivitesController>();
    } catch (e) {
      return Get.put(ActivitesController());
    }
  }

  static HomeController get homeCtrl {
    try {
      return Get.find<HomeController>();
    } catch (e) {
      return Get.put(HomeController());
    }
  }
}
