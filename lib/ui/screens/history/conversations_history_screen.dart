import 'package:botroad/controllers/conversations_controller.dart';
import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConversationsHistoryScreen extends StatefulWidget {
  const ConversationsHistoryScreen({super.key});

  @override
  State<ConversationsHistoryScreen> createState() =>
      _ConversationsHistoryScreenState();
}

class _ConversationsHistoryScreenState
    extends State<ConversationsHistoryScreen> {
  final ConversationsController conversationsCtrl = Setting.conversationsCtrl;
  List<ConversationsModel> conversations = [];
  List<ConversationsModel> filteredConversations = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  final int pageSize = 20;
  int currentPage = 0;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 0;
        conversations = [];
        hasMoreData = true;
      });
    }

    if (!hasMoreData) return;

    setState(() {
      isLoading = true;
    });

    try {
      final userConversations = await conversationsCtrl.getConversationsOfUser(
        Setting.userCtrl.user.value.key!,
        limit: pageSize,
        startAfter: currentPage > 0 ? conversations.last : null,
      );

      if (userConversations != null) {
        setState(() {
          if (refresh) {
            conversations = userConversations;
          } else {
            conversations.addAll(userConversations);
          }
          hasMoreData = userConversations.length == pageSize;
          currentPage++;
          _filterConversations();
        });
      }
    } catch (e) {
      printDebug("Error loading conversations: $e");
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'historique des conversations',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterConversations() {
    if (searchQuery.isEmpty) {
      filteredConversations = List.from(conversations);
    } else {
      filteredConversations =
          conversations.where((conversation) {
            final title = conversation.libelle?.toLowerCase() ?? '';
            final date = _formatDate(conversation.date_create).toLowerCase();
            final query = searchQuery.toLowerCase();
            return title.contains(query) || date.contains(query);
          }).toList();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Aujourd\'hui, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Hier, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} jours, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des conversations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadConversations(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterConversations();
                });
              },
            ),
          ),
          Expanded(
            child:
                isLoading && conversations.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredConversations.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty
                                ? 'Aucune conversation'
                                : 'Aucun résultat trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () => _loadConversations(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredConversations.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filteredConversations.length) {
                            if (!hasMoreData) {
                              return const SizedBox.shrink();
                            }
                            if (isLoadingMore) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return Center(
                              child: TextButton(
                                onPressed: () async {
                                  setState(() {
                                    isLoadingMore = true;
                                  });
                                  await _loadConversations();
                                  setState(() {
                                    isLoadingMore = false;
                                  });
                                },
                                child: const Text('Charger plus'),
                              ),
                            );
                          }

                          final conversation = filteredConversations[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: const Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                conversation.libelle ?? 'Nouvelle conversation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatDate(conversation.date_create),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Get.to(
                                  () =>
                                      AIChatScreen(conversation: conversation),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
