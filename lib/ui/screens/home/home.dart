import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/models/user_model.dart';
import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/ui/screens/history/conversations_history_screen.dart';
import 'package:botroad/ui/widgets/boutton.dart';
import 'package:botroad/ui/widgets/drawer.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? user;
  List<ConversationsModel> recentConversations = [];
  bool isLoadingConversations = true;

  @override
  void initState() {
    super.initState();
    user = Setting.userCtrl.user.value;
    Setting.userCtrl.openStreams();
    _loadRecentConversations();
  }

  Future<void> _loadRecentConversations() async {
    setState(() {
      isLoadingConversations = true;
    });

    try {
      final conversations = await Setting.conversationsCtrl
          .getConversationsOfUser(Setting.userCtrl.user.value.key!, limit: 3);

      if (conversations != null) {
        setState(() {
          recentConversations = conversations;
        });
      }
    } catch (e) {
      printDebug("Error loading recent conversations: $e");
    } finally {
      setState(() {
        isLoadingConversations = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      final time = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

      if (difference.inDays == 0) {
        return '${'home_today'.tr}, $time';
      } else if (difference.inDays == 1) {
        return '${'home_yesterday'.tr}, $time';
      } else if (difference.inDays < 7) {
        return '${'home_days_ago'.trParams({'count': '${difference.inDays}'})}, $time';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = Setting.getHeight(context);
    final spacing = height / 20;

    return Scaffold(
      drawer: DrawerCustom(),
      drawerScrimColor: Colors.black.withValues(alpha: 0.35),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'BotRoad',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Setting.userCtrl.deconnectUser();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: Setting.getHeight(context) / 3.8,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 36,
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(Assets.logo),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Text(
                'home_welcome'.tr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 34,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'BOTROAD',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing),
              Text(
                'home_start_ai_chat'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Boutton(
                text: 'home_start_chat'.tr,
                onPressed: () {
                  Get.to(() => const AIChatScreen());
                },
              ),
              const SizedBox(height: 10),
              if (recentConversations.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'home_recent_conversations'.tr,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Get.to(
                                  () => const ConversationsHistoryScreen(),
                                );
                              },
                              child: Text('home_see_all'.tr),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...recentConversations.map(
                        (conversation) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppColors.surfaceElevated,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.chat, color: Colors.white),
                            ),
                            title: Text(
                              conversation.libelle ??
                                  'home_new_conversation'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatDate(conversation.date_create),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                            onTap: () {
                              Get.to(
                                () => AIChatScreen(conversation: conversation),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
