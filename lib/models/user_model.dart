import 'package:botroad/bd/columns.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? key;
  String? email;
  String? password;
  String? google_id;
  String? nom;
  String? date_create;
  String? date_active;
  String? date_connexion;
  String? date_admin;
  bool? is_active;
  bool? is_admin;

  UserModel({
    this.key,
    this.email,
    this.password,
    this.google_id,
    this.nom,
    this.date_create,
    this.date_active,
    this.date_connexion,
    this.date_admin,
    this.is_active,
    this.is_admin,
  });

  UserModel.fromJson(dynamic map)
    : key = map[BDColumnNames.User_key],
      email = map[BDColumnNames.User_email],
      google_id = map[BDColumnNames.User_google_id],
      nom = map[BDColumnNames.User_nom],
      date_create =
          map[BDColumnNames.User_date_create] != null
              ? map[BDColumnNames.User_date_create] is String
                  ? map[BDColumnNames.User_date_create]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.User_date_create].millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_active =
          map[BDColumnNames.User_date_active] != null
              ? map[BDColumnNames.User_date_active] is String
                  ? map[BDColumnNames.User_date_active]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.User_date_active].millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_connexion =
          map[BDColumnNames.User_date_connexion] != null
              ? map[BDColumnNames.User_date_connexion] is String
                  ? map[BDColumnNames.User_date_connexion]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.User_date_connexion]
                        .millisecondsSinceEpoch,
                  ).toString()
              : null,
      date_admin =
          map[BDColumnNames.User_date_admin] != null
              ? map[BDColumnNames.User_date_admin] is String
                  ? map[BDColumnNames.User_date_admin]
                  : DateTime.fromMillisecondsSinceEpoch(
                    map[BDColumnNames.User_date_admin].millisecondsSinceEpoch,
                  ).toString()
              : null,
      is_active = map[BDColumnNames.User_is_active],
      is_admin = map[BDColumnNames.User_is_admin];

  Map<String, dynamic> toJson() {
    return {
      BDColumnNames.User_key: key,
      BDColumnNames.User_email: email,
      BDColumnNames.User_google_id: google_id,
      BDColumnNames.User_nom: nom,
      BDColumnNames.User_date_create:
          date_create ?? FieldValue.serverTimestamp(),
      BDColumnNames.User_date_active:
          date_active ?? FieldValue.serverTimestamp(),
      BDColumnNames.User_date_connexion:
          date_connexion ?? FieldValue.serverTimestamp(),
      BDColumnNames.User_date_admin: date_admin ?? FieldValue.serverTimestamp(),
      BDColumnNames.User_is_active: is_active,
      BDColumnNames.User_is_admin: is_admin,
    };
  }

  UserModel copyWith({
    String? key,
    String? email,
    String? password,
    String? google_id,
    String? nom,
    String? date_create,
    String? date_active,
    String? date_connexion,
    String? date_admin,
    bool? is_active,
    bool? is_admin,
  }) {
    return UserModel(
      key: key ?? this.key,
      email: email ?? this.email,
      password: password ?? this.password,
      google_id: google_id ?? this.google_id,
      nom: nom ?? this.nom,
      date_create: date_create ?? this.date_create,
      date_active: date_active ?? this.date_active,
      date_connexion: date_connexion ?? this.date_connexion,
      date_admin: date_admin ?? this.date_admin,
      is_active: is_active ?? this.is_active,
      is_admin: is_admin ?? this.is_admin,
    );
  }
}
