import 'package:botroad/bd/columns.dart';
import 'package:botroad/controllers/conversations_controller.dart';
import 'package:botroad/controllers/messages_controller.dart';
import 'package:botroad/core/config/app_secrets.dart';
import 'package:botroad/core/services/chat_intent_service.dart';
import 'package:botroad/core/services/chat_navigation_service.dart';
import 'package:botroad/core/services/geocoding_service.dart';
import 'package:botroad/core/services/location_service.dart';
import 'package:botroad/core/services/nearby_places_service.dart';
import 'package:botroad/core/services/network_status_service.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/core/services/route_risk_service.dart';
import 'package:botroad/core/services/routing_service.dart';
import 'package:botroad/core/services/trip_history_service.dart';
import 'package:botroad/core/models/route_result.dart';
import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/models/messages_model.dart';
import 'package:botroad/models/routes_model.dart';
import 'package:botroad/services/gemini_service.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:botroad/ui/screens/home/iteneraire.dart';
import 'package:botroad/ui/widgets/network_status_banner.dart';
import 'package:botroad/controllers/locations_controller.dart';
import 'package:botroad/controllers/routes_controller.dart';
import 'package:geolocator/geolocator.dart';

class AIChatScreen extends StatefulWidget {
  final ConversationsModel? conversation;

  const AIChatScreen({super.key, this.conversation});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final MessagesController messagesCtrl = Setting.messagesCtrl;
  final ConversationsController conversationsCtrl = Setting.conversationsCtrl;
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;
  bool isTyping = false;
  bool isSearching = false;
  bool isLoadingMore = false;
  bool hasMoreMessages = true;
  bool _didShowMessagesStreamError = false;
  String searchQuery = '';
  GeminiService? geminiService;
  ConversationsModel? conversations;
  static const int messagesPerPage = 20;
  DocumentSnapshot? lastDocument;
  List<MessagesModel> loadedMessages = [];
  List<Map<String, String>> conversationMemory = [];
  static const int maxMemorySize = 10;
  final LocationsController locationsCtrl = Setting.locationsCtrl;
  final RoutesController routesCtrl = Setting.routesCtrl;
  late final LocationService locationService;
  late final ChatNavigationService chatNavigationService;
  late final NearbyPlacesService nearbyPlacesService;
  late final NetworkStatusService networkStatusService;
  late final RoadReportService roadReportService;
  late final RouteRiskService routeRiskService;
  late final RoutingService routingService;
  late final TripHistoryService tripHistoryService;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    conversations = widget.conversation;
    initAiServices();
    _setupScrollListener();
    _getCurrentLocation();
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });
  }

  void initAiServices() {
    geminiService = GeminiService();
    locationService = LocationService();
    chatNavigationService = ChatNavigationService(
      chatIntentService: ChatIntentService(),
      locationService: locationService,
      geocodingService: GeocodingService(apiKey: AppSecrets.googleMapsApiKey),
    );
    nearbyPlacesService = NearbyPlacesService(
      apiKey: AppSecrets.googleMapsApiKey,
    );
    networkStatusService =
        Get.isRegistered<NetworkStatusService>()
            ? Get.find<NetworkStatusService>()
            : Get.put(NetworkStatusService(), permanent: true);
    roadReportService = RoadReportService(collection: Setting.fRoadReports);
    routeRiskService = RouteRiskService(collection: Setting.fRoadReports);
    routingService = RoutingService(
      googleApiKey: AppSecrets.googleMapsApiKey,
    );
    tripHistoryService = TripHistoryService(collection: Setting.fTripHistory);
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateConversationMemory(String sender, String content) {
    conversationMemory.insert(0, {'sender': sender, 'content': content});
    if (conversationMemory.length > maxMemorySize) {
      conversationMemory.removeLast();
    }
  }

  bool _isNetworkError(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('unable to resolve host') ||
        normalized.contains('unknownhostexception') ||
        normalized.contains('socketexception') ||
        normalized.contains('failed to resolve name') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('status{code=unavailable') ||
        normalized.contains('code=unavailable') ||
        normalized.contains('end of stream or ioexception') ||
        normalized.contains('ioexception') ||
        normalized.contains('broken pipe');
  }

  String _toFriendlyErrorMessage(Object error) {
    if (_isNetworkError(error)) {
      networkStatusService.markOffline();
      return 'chat_network_error_message'.tr;
    }

    return error
        .toString()
        .replaceFirst('Exception: Error generating response: ', '')
        .replaceFirst('Exception: Error generating Gemini response: ', '')
        .replaceFirst('Exception: ', '');
  }

  void _showErrorSnackBar(String message) {
    Get.snackbar(
      'chat_send_error_title'.tr,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          return;
        }
      }
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      printDebug("Error getting location: $e");
    }
  }

  String _buildConversationContext() {
    final context = '''
Tu es BotRoad, un assistant IA spécialisé dans la navigation et la recherche de lieux. Ton rôle est d'aider les utilisateurs à trouver des itinéraires et des lieux.

Instructions spécifiques :
1. Si l'utilisateur demande un itinéraire ou cherche un lieu, aide-le à trouver la meilleure route.
2. Si la question n'est pas liée à la navigation ou aux lieux, explique poliment que tu es spécialisé dans l'aide à la navigation.
3. Tu peux communiquer en français ou en anglais selon la langue utilisée par l'utilisateur.
4. Utilise le contexte de la conversation précédente pour maintenir la cohérence.

IMPORTANT - Format de réponse pour les itinéraires :
Si tu as toutes les informations nécessaires (départ, arrivée, étapes), réponds au format JSON suivant :
{
  "depart": "nom du lieu de départ",
  "arrivee": "nom du lieu d'arrivée",
  "etapes": ["étape 1", "étape 2", ...]
}

Si le départ n'est pas spécifié, renvoie "position_actuelle" dans le champ "depart".
Si des informations manquent, réponds normalement en expliquant ce qui manque.

Historique de la conversation :
${conversationMemory.map((msg) => "${msg['sender']}: ${msg['content']}").join('\n')}
''';
    return context;
  }

  Future<void> _handleStructuredResponse(
    Map<String, dynamic> response,
    String conversationId,
  ) async {
    printDebug("response ai : $response");
    if (response.containsKey('depart') && response.containsKey('arrivee')) {
      // Rechercher les lieux
      final depart = response['depart'] as String;
      final arrivee = response['arrivee'] as String;
      final etapes = _sanitizeEtapes(
        (response['etapes'] as List<dynamic>?)?.cast<String>() ?? [],
        arrivee,
      );

      printDebug("depart : $depart");
      printDebug("arrivee : $arrivee");
      printDebug("etapes : $etapes");
      // Rechercher le lieu de départ
      var departPlace =
          depart == 'position_actuelle' && currentPosition != null
              ? {
                'latitude': currentPosition!.latitude,
                'longitude': currentPosition!.longitude,
              }
              : await locationsCtrl.searchPlace(depart);
      printDebug("departPlace : $departPlace");

      // Rechercher le lieu d'arrivée
      var arriveePlace = await locationsCtrl.searchPlace(arrivee);
      printDebug("arriveePlace : $arriveePlace");

      // Rechercher les étapes
      List<Map<String, dynamic>> etapesPlaces = [];
      for (var etape in etapes) {
        var place = await locationsCtrl.searchPlace(etape);
        if (place != null) {
          etapesPlaces.add(place);
        }
      }
      printDebug("etapesPlaces : $etapesPlaces");

      // Vérifier si tous les lieux ont été trouvés
      if (departPlace != null && arriveePlace != null) {
        // Créer la route
        final route = await routesCtrl.createRoute(
          departPlace['latitude'] as double,
          departPlace['longitude'] as double,
          arriveePlace['latitude'] as double,
          arriveePlace['longitude'] as double,
          etapesPlaces,
          "De $depart à $arrivee",
        );

        if (route != null) {
          // Naviguer vers la page d'itinéraire
          Get.to(() => Iteneraire(route: route));
          return;
        }
        await _saveBotMessage(
          conversationId,
          "J'ai bien compris votre trajet et retrouve les lieux, mais l'affichage automatique de l'itineraire ne fonctionne pas encore correctement sur le web. Essayez sur Android pour la carte complete, ou reformulez sans etapes intermediaires.",
        );
        return;
      }

      // Si quelque chose n'a pas fonctionné, demander à l'IA d'expliquer le problème
      final errorContext = '''
Les lieux suivants n'ont pas pu être trouvés :
${departPlace == null ? '- Départ: $depart\n' : ''}
${arriveePlace == null ? '- Arrivée: $arrivee\n' : ''}
${etapesPlaces.length < etapes.length ? '- Certaines étapes\n' : ''}

Explique poliment à l'utilisateur quels lieux n'ont pas pu être trouvés et demande-lui de préciser ou de reformuler.
''';

      final errorResponse = await geminiService?.generateResponse(
        "Explique le problème",
        context: errorContext,
      );

      if (errorResponse != null) {
        messagesCtrl.messages.value = MessagesModel(
          id_conversation: conversationId,
          sender: 'bot',
          content: errorResponse['message'] as String,
          date_create: DateTime.now().toString(),
        );
        await messagesCtrl.addMessages();
        _updateConversationMemory('bot', errorResponse['message'] as String);
      }
    } else {
      // Si ce n'est pas une réponse structurée, l'afficher normalement
      final message = response['message'] as String;
      messagesCtrl.messages.value = MessagesModel(
        id_conversation: conversationId,
        sender: 'bot',
        content: message,
        date_create: DateTime.now().toString(),
      );
      await messagesCtrl.addMessages();
      _updateConversationMemory('bot', message);
    }
  }

  Future<bool> _tryHandleMvpNavigation(
    String content,
    String conversationId,
  ) async {
    try {
      final navigationResult = await chatNavigationService.processMessage(
        message: content,
        userId: Setting.userCtrl.user.value.key,
      );

      final request = navigationResult.request;

      if (request.intent == ChatIntentService.calculateRouteIntent &&
          navigationResult.isReadyForRouting) {
        final rawRouteResult = await routingService.calculateRoute(
          userId: Setting.userCtrl.user.value.key,
          startLat: request.startLat!,
          startLng: request.startLng!,
          destinationLat: request.destinationLat!,
          destinationLng: request.destinationLng!,
          startLabel: request.startText,
          destinationLabel: request.destinationText,
        );

        if (rawRouteResult != null) {
          final routeResult = await routeRiskService.attachWarnings(rawRouteResult);
          final route = await _persistRouteResult(routeResult);
          if (route == null) {
            await _saveBotMessage(
              conversationId,
              "J'ai calcule l'itineraire, mais je n'ai pas pu l'enregistrer pour l'affichage.",
            );
            return true;
          }

          await _saveTripHistory(content, routeResult);

          final warningText = routeResult.warnings.isNotEmpty
              ? " Attention, ${routeResult.warnings.length} signalement(s) de route ont ete detecte(s) sur ou pres de cet itineraire."
              : '';
          final botMessage =
              "J'ai trouve un itineraire de ${routeResult.startLabel ?? request.startText ?? 'votre position actuelle'} vers ${routeResult.destinationLabel ?? request.destinationText ?? 'la destination'}. Distance estimee: ${routeResult.distance.toStringAsFixed(1)} km, duree estimee: ${routeResult.duration.toStringAsFixed(0)} min.$warningText Je l'affiche sur la carte.";

          await _saveBotMessage(conversationId, botMessage);
          Get.to(() => Iteneraire(route: route));
          return true;
        }
      }

      if (request.intent == ChatIntentService.calculateRouteIntent &&
          !navigationResult.isReadyForRouting) {
        final botMessage = _buildNavigationFailureMessage(navigationResult);
        await _saveBotMessage(conversationId, botMessage);
        return true;
      }

      if (request.intent == ChatIntentService.findNearbyPlaceIntent) {
        if (request.category == null || request.category!.trim().isEmpty) {
          await _saveBotMessage(
            conversationId,
            "J'ai compris que vous cherchez un lieu proche, mais je n'ai pas reconnu la categorie demandee.",
          );
          return true;
        }

        if (request.startLat == null || request.startLng == null) {
          await _saveBotMessage(
            conversationId,
            "Je n'ai pas pu determiner votre position actuelle pour rechercher les lieux proches.",
          );
          return true;
        }

        final places = await nearbyPlacesService.findNearbyPlaces(
          latitude: request.startLat!,
          longitude: request.startLng!,
          category: request.category!,
          resultCount: request.resultCount ?? 1,
        );

        if (places.isEmpty) {
          await _saveBotMessage(
            conversationId,
            "Je n'ai trouve aucun ${request.category} proche pour le moment.",
          );
          return true;
        }

        final lines = places.map((place) {
          final distance = place.distance?.toStringAsFixed(1) ?? '?';
          final rating =
              place.rating != null ? ' - note ${place.rating!.toStringAsFixed(1)}' : '';
          return "- ${place.name} (${distance} km${rating})";
        }).join('\n');

        final title =
            (request.resultCount ?? 1) > 1
                ? "Voici les ${places.length} ${request.category} les plus proches :"
                : "Voici le ${request.category} le plus proche :";

        await _saveBotMessage(
          conversationId,
          "$title\n$lines",
        );
        return true;
      }

      if (request.intent == ChatIntentService.showTripHistoryIntent) {
        final userId = Setting.userCtrl.user.value.key;
        if (userId == null) {
          await _saveBotMessage(
            conversationId,
            "Je n'ai pas pu retrouver votre identifiant utilisateur pour charger l'historique.",
          );
          return true;
        }

        final historyItems = await tripHistoryService.getTripHistoryForUser(
          userId,
          limit: 5,
        );

        if (historyItems.isEmpty) {
          await _saveBotMessage(
            conversationId,
            "Je n'ai trouve aucun trajet enregistre pour le moment.",
          );
          return true;
        }

        final lines = historyItems.map((item) {
          final origin = item.originLabel ?? 'Depart inconnu';
          final destination = item.destinationLabel ?? 'Destination inconnue';
          final distance = item.distance.toStringAsFixed(1);
          final duration = item.duration.toStringAsFixed(0);
          return "- $origin -> $destination ($distance km, $duration min)";
        }).join('\n');

        await _saveBotMessage(
          conversationId,
          "Voici vos 5 derniers trajets :\n$lines",
        );
        return true;
      }

      if (request.intent == ChatIntentService.reportBadRoadIntent) {
        final currentLocation = await locationService.getCurrentLocation();
        if (currentLocation == null) {
          await _saveBotMessage(
            conversationId,
            "Je n'ai pas pu recuperer votre position actuelle pour enregistrer le signalement.",
          );
          return true;
        }

        final report = roadReportService.buildUserReport(
          userId: Setting.userCtrl.user.value.key,
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
          comment: content,
        );

        final reportId = await roadReportService.saveRoadReport(report);
        if (reportId == null) {
          await _saveBotMessage(
            conversationId,
            "Le signalement n'a pas pu etre enregistre pour le moment. Reessayez plus tard.",
          );
          return true;
        }

        await _saveBotMessage(
          conversationId,
          "Votre signalement de route a bien ete enregistre. Merci pour votre contribution.",
        );
        return true;
      }

      return false;
    } catch (e) {
      printDebug("error mvp navigation ::: $e");
      return false;
    }
  }

  Future<RoutesModel?> _persistRouteResult(RouteResult routeResult) async {
    final points =
        routeResult.geometry
            .map(
              (point) => '${point['latitude']},${point['longitude']}',
            )
            .join('|');

    final route = RoutesModel(
      id_user: routeResult.userId,
      nom:
          'De ${routeResult.startLabel ?? 'position actuelle'} vers ${routeResult.destinationLabel ?? 'destination'}',
      points: points,
      waypoints: const [],
      warnings: routeResult.warnings,
      date_create: DateTime.now().toString(),
    );

    routesCtrl.routes.value = route;
    final key = await routesCtrl.addRoutes();
    if (key == null) {
      return null;
    }

    route.key = key;
    return route;
  }

  Future<void> _saveTripHistory(
    String originalMessage,
    RouteResult routeResult,
  ) async {
    final tripHistory = tripHistoryService.buildTripHistory(
      originalMessage: originalMessage,
      routeResult: routeResult,
    );
    await tripHistoryService.saveTripHistory(tripHistory);
  }

  String _buildNavigationFailureMessage(ChatNavigationResult result) {
    switch (result.failureReason) {
      case 'missing_destination':
        return "Je n'ai pas pu identifier la destination. Precisez ou vous voulez aller.";
      case 'destination_not_found':
        return "Je n'ai pas pu localiser la destination demandee. Essayez avec un nom de lieu plus precis.";
      case 'start_location_not_resolved':
        return "Je n'ai pas pu determiner le point de depart. Activez la localisation ou precisez votre lieu de depart.";
      case 'missing_category':
        return "Je n'ai pas pu identifier la categorie de lieu recherchee.";
      case 'reference_location_not_resolved':
        return "Je n'ai pas pu determiner votre position actuelle pour lancer cette recherche.";
      default:
        return "Je n'ai pas encore pu traiter cette demande automatiquement. Reformulez-la ou essayez avec plus de precision.";
    }
  }

  List<String> _sanitizeEtapes(List<String> etapes, String arrivee) {
    final results = <String>[];
    final seen = <String>{};

    for (final rawEtape in etapes) {
      final etape = rawEtape.trim();
      if (etape.isEmpty) continue;

      final normalized = etape.toLowerCase();
      if (normalized == arrivee.trim().toLowerCase()) continue;

      final looksLikeInstruction = [
        'tourner',
        'continuer',
        'rejoindre',
        'suivre',
        'prendre l',
        'prendre la',
        'prendre le',
        'prendre les',
        'direction du',
        'direction de',
        'traversant',
      ].any(normalized.contains);

      if (looksLikeInstruction) continue;
      if (seen.add(normalized)) {
        results.add(etape);
      }
    }

    return results;
  }

  Future<void> _saveBotMessage(String conversationId, String message) async {
    try {
      messagesCtrl.messages.value = MessagesModel(
        id_conversation: conversationId,
        sender: 'bot',
        content: message,
        date_create: DateTime.now().toString(),
      );
      await messagesCtrl.addMessages();
      _updateConversationMemory('bot', message);
    } catch (e) {
      printDebug("error saveBotMessage ::: $e");
    }
  }

  Future<void> _sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;
    String? conversationId = widget.conversation?.key ?? conversations?.key;

    messageController.clear();
    setState(() {
      isLoading = true;
      isTyping = true;
    });

    try {

      // Si pas de conversation, en créer une nouvelle
      if (conversationId == null) {
        conversationsCtrl.conversations.value = ConversationsModel(
          id_user: Setting.userCtrl.user.value.key,
          libelle:
              content.length > 30 ? '${content.substring(0, 30)}...' : content,
        );
        conversationId = await conversationsCtrl.addConversations();

        if (conversationId == null) {
          throw Exception('Failed to create conversation');
        }
        conversations = await Setting.conversationsCtrl.getOneConversations(
          conversationId,
        );
        if (conversations?.key == null) {
          throw Exception('Failed to get conversation');
        }
      }

      // Sauvegarder le message de l'utilisateur
      messagesCtrl.messages.value = MessagesModel(
        id_conversation: conversationId,
        sender: 'user',
        content: content,
        date_create: DateTime.now().toString(),
      );
      await messagesCtrl.addMessages();
      _updateConversationMemory('user', content);

      final handledByMvp = await _tryHandleMvpNavigation(content, conversationId);
      if (handledByMvp) {
        networkStatusService.markOnline();
        _scrollToBottom();
        return;
      }

      // Generate response using our custom service with context
      final context = _buildConversationContext();
      final response = await geminiService?.generateResponse(
        content,
        context: context,
      );

      if (response != null) {
        await _handleStructuredResponse(response, conversationId);
      }

      networkStatusService.markOnline();
      _scrollToBottom();
    } catch (e) {
      final friendlyError = _toFriendlyErrorMessage(e);

      if (conversationId != null) {
        await _saveBotMessage(conversationId, friendlyError);
      }

      _showErrorSnackBar(
        'chat_send_error_body'.trParams({'error': friendlyError}),
      );
      printDebug("error sendMessage ::: $e");
    } finally {
      setState(() {
        isLoading = false;
        isTyping = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (isLoadingMore || !hasMoreMessages || searchQuery.isNotEmpty) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      if (conversations?.key == null) return;

      var query = Setting.fMessages
          .where(
            BDColumnNames.Messages_id_conversation,
            isEqualTo: conversations!.key,
          )
          .orderBy(BDColumnNames.Messages_date_create, descending: true)
          .limit(messagesPerPage);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasMoreMessages = false;
        });
        return;
      }

      final newMessages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final message = MessagesModel.fromJson(data);
            message.key = doc.id;
            return message;
          }).toList();

      setState(() {
        loadedMessages.addAll(newMessages);
        lastDocument = snapshot.docs.last;
        hasMoreMessages = snapshot.docs.length == messagesPerPage;
      });
    } catch (e) {
      if (_isNetworkError(e)) {
        networkStatusService.markOffline();
        _showErrorSnackBar('chat_history_network_error'.tr);
      }
      printDebug("Error loading more messages: $e");
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Stream<List<MessagesModel>> _getMessagesStream() {
    if (conversations?.key == null) return Stream.value([]);

    var query = Setting.fMessages
        .where(
          BDColumnNames.Messages_id_conversation,
          isEqualTo: conversations!.key,
        )
        .orderBy(BDColumnNames.Messages_date_create, descending: true)
        .limit(messagesPerPage);

    if (searchQuery.isNotEmpty) {
      return query.snapshots().map((snapshot) {
        final messages =
            snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  final message = MessagesModel.fromJson(data);
                  message.key = doc.id;
                  return message;
                })
                .where(
                  (message) =>
                      message.content?.toLowerCase().contains(
                        searchQuery.toLowerCase(),
                      ) ??
                      false,
                )
                .toList();

        setState(() {
          loadedMessages = messages;
          hasMoreMessages = false;
        });

        return messages;
      });
    }

    return query.snapshots().map((snapshot) {
      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final message = MessagesModel.fromJson(data);
            message.key = doc.id;
            return message;
          }).toList();

      setState(() {
        loadedMessages = messages;
        lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        hasMoreMessages = snapshot.docs.length == messagesPerPage;
      });

      return messages;
    });
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'chat_typing'.tr,
            style: TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(conversations?.libelle ?? 'chat_new_conversation'.tr),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchQuery = '';
                  searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          if (isSearching)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'chat_search_messages'.tr,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                searchController.clear();
                              });
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          Expanded(
            child: StreamBuilder<List<MessagesModel>>(
              stream: _getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final friendlyError = _toFriendlyErrorMessage(snapshot.error!);
                  if (!_didShowMessagesStreamError) {
                    _didShowMessagesStreamError = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _showErrorSnackBar(
                          'chat_send_error_body'.trParams({
                            'error': friendlyError,
                          }),
                        );
                      }
                    });
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'chat_error_prefix'.trParams({
                          'error': friendlyError,
                        }),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                networkStatusService.markOnline();
                _didShowMessagesStreamError = false;
                // printDebug(
                //   "snapshot.hasData: ${snapshot.hasData} et snapshot.connectionState: ${snapshot.connectionState}",
                // );

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = loadedMessages;

                return ListView.builder(
                  reverse: true,
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      messages.length +
                      (isTyping ? 1 : 0) +
                      (hasMoreMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isTyping && index == 0) {
                      return _buildTypingIndicator();
                    }

                    if (hasMoreMessages &&
                        index == messages.length + (isTyping ? 1 : 0) &&
                        messages.isNotEmpty) {
                      return _buildLoadMoreIndicator();
                    }
                    if (messages.isEmpty) {
                      return Center(child: Text('chat_no_message_found'.tr));
                    }

                    final message = messages[isTyping ? index - 1 : index];
                    final isUser = message.sender == 'user';

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: InkWell(
                        onDoubleTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'chat_resend_message'.tr,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      (message.content ?? '').length > 50
                                          ? '${(message.content ?? '').substring(0, 50)}...'
                                          : message.content ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('chat_no'.tr),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Renvoyer le message
                                            if (message.content != null) {
                                              // sendMessage(message.content!);
                                              messageController.text =
                                                  message.content!;
                                              _sendMessage();
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text('chat_yes'.tr),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isUser ? AppColors.primary : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.date_create != null
                                    ? DateTime.parse(
                                      message.date_create!,
                                    ).toLocal().toString().substring(0, 16)
                                    : '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isUser
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'chat_write_message'.tr,
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
