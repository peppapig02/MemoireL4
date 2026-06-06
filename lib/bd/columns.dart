class BDColumnNames {
  static String dateCreate = "date_create";

  ///USER
  static String User_key = "key";
  static String User_email = "email";
  static String User_password = "password";
  static String User_google_id = "google_id";
  static String User_nom = "nom";
  static String User_date_create = "date_create";
  static String User_date_active = "date_active";
  static String User_date_connexion = "date_connexion";
  static String User_date_admin = "date_admin";
  static String User_is_active = "is_active";
  static String User_is_admin = "is_admin";

  ///CONVERSATIONS
  static String Conversations_key = "key";
  static String Conversations_id_user = "id_user";
  static String Conversations_libelle = "libelle";
  static String Conversations_date_create = "date_create";

  ///MESSAGES
  static String Messages_key = "key";
  static String Messages_id_conversation = "id_conversation";
  static String Messages_sender = "sender";
  static String Messages_content = "content";
  static String Messages_date_create = "date_create";

  ///LOCATIONS
  static String Locations_key = "key";
  static String Locations_nom = "nom";
  static String Locations_place_id = "place_id";
  static String Locations_category = "category";
  static String Locations_popularity_score = "popularity_score";
  static String Locations_latitude = "latitude";
  static String Locations_longitude = "longitude";
  static String Locations_date_create = "date_create";
  static String Locations_id_user = "id_user";

  ///ROUTES
  static String Routes_key = "key";
  static String Routes_id_user = "id_user";
  static String Routes_origin_id = "origin_id";
  static String Routes_destination_id = "destination_id";
  static String Routes_waypoints = "waypoints";
  static String Routes_date_create = "date_create";
  static String Routes_points = "points";
  static String Routes_nom = "nom";
  static String Routes_warnings = "warnings";
  static String Routes_segments = "segments";
  static String Routes_mode = "mode";
  static String Routes_risk_score = "risk_score";

  ///TRENDING_LOCATIONS
  static String Trending_locations_key = "key";
  static String Trending_locations_id_location = "id_location";
  static String Trending_locations_count = "count";
  static String Trending_locations_period = "period";
  static String Trending_locations_date_create = "date_create";
  static String Trending_locations_id_user = "id_user";

  ///ADS
  static String Ads_key = "key";
  static String Ads_title = "title";
  static String Ads_description = "description";
  static String Ads_target_location = "target_location";
  static String Ads_date_create = "date_create";
  static String Ads_date_active = "date_active";
  static String Ads_date_begin = "date_begin";
  static String Ads_date_end = "date_end";
  static String Ads_amount = "amount";
  static String Ads_is_active = "is_active";
  static String Ads_id_user_admin = "id_user_admin";

  ///ACTIVITES
  static String Activites_key = "key";
  static String Activites_type = "type";
  static String Activites_id_type = "id_type";
  static String Activites_id_user = "id_user";
  static String Activites_libelle = "libelle";
  static String Activites_data_before = "data_before";
  static String Activites_data_after = "data_after";
  static String Activites_date_create = "date_create";
}
