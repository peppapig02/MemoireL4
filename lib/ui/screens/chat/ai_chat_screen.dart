import 'package:botroad/bd/columns.dart';
import 'package:botroad/controllers/conversations_controller.dart';
import 'package:botroad/controllers/home_controller.dart';
import 'package:botroad/controllers/messages_controller.dart';
import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/models/messages_model.dart';
import 'package:botroad/services/openai_service.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:botroad/ui/screens/home/iteneraire.dart';
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
  final HomeController homeCtrl = Setting.homeCtrl;
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;
  bool isTyping = false;
  bool isSearching = false;
  bool isLoadingMore = false;
  bool hasMoreMessages = true;
  String searchQuery = '';
  OpenAIService? openAIService;
  ConversationsModel? conversations;
  static const int messagesPerPage = 20;
  DocumentSnapshot? lastDocument;
  List<MessagesModel> loadedMessages = [];
  List<Map<String, String>> conversationMemory = [];
  static const int maxMemorySize = 10;
  final LocationsController locationsCtrl = Setting.locationsCtrl;
  final RoutesController routesCtrl = Setting.routesCtrl;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    conversations = widget.conversation;
    initOpenAIService();
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

  void initOpenAIService() {
    openAIService = OpenAIService(apiKey: homeCtrl.openaikey);
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
      final etapes =
          (response['etapes'] as List<dynamic>?)?.cast<String>() ?? [];

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
      }

      // Si quelque chose n'a pas fonctionné, demander à l'IA d'expliquer le problème
      final errorContext = '''
Les lieux suivants n'ont pas pu être trouvés :
${departPlace == null ? '- Départ: $depart\n' : ''}
${arriveePlace == null ? '- Arrivée: $arrivee\n' : ''}
${etapesPlaces.length < etapes.length ? '- Certaines étapes\n' : ''}

Explique poliment à l'utilisateur quels lieux n'ont pas pu être trouvés et demande-lui de préciser ou de reformuler.
''';

      final errorResponse = await openAIService?.generateResponse(
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

  Future<void> _sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty) return;

    messageController.clear();
    setState(() {
      isLoading = true;
      isTyping = true;
    });

    try {
      String? conversationId = widget.conversation?.key ?? conversations?.key;

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

      // Generate response using our custom service with context
      final context = _buildConversationContext();
      final response = await openAIService?.generateResponse(
        content,
        context: context,
      );

      if (response != null) {
        await _handleStructuredResponse(response, conversationId);
      }

      _scrollToBottom();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue lors de l\'envoi du message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
            'Bot est en train d\'écrire...',
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
        title: Text(conversations?.libelle ?? 'Nouvelle conversation'),
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
          if (isSearching)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher dans les messages...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon:
                      searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear),
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
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
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
                      return const Center(child: Text('Aucun message trouvé'));
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
                                    const Text(
                                      'Renvoyer ce message ?',
                                      style: TextStyle(
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
                                          child: const Text('Non'),
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
                                          child: const Text('Oui'),
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
                    decoration: const InputDecoration(
                      hintText: 'Écrivez votre message...',
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
