import 'package:botroad/models/conversations_model.dart';
import 'package:botroad/models/user_model.dart';
import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/ui/screens/credits/buy_credits_screen.dart';
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
      final conversations = await Setting.conversationsCtrl.getConversationsOfUser(
        Setting.userCtrl.user.value.key!,
        limit: 3,
      );

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
      drawerScrimColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                height: Setting.getHeight(context) / 3.5,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.logo),
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Text(
                'home_welcome'.tr,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 40,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'BOTROAD',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                  fontSize: 35,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing),
              Text(
                'home_start_ai_chat'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'home_credit_level'.tr,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    user?.credits ?? '0',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              SizedBox(height: spacing),
              InkWell(
                onTap: () {
                  Get.to(() => const BuyCreditsScreen());
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.credit_card),
                    const SizedBox(width: 10),
                    Text(
                      'home_buy_credits'.tr,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
              SizedBox(height: spacing),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Get.to(() => const ConversationsHistoryScreen());
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
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.chat,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              conversation.libelle ?? 'home_new_conversation'.tr,
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
                                () => AIChatScreen(
                                  conversation: conversation,
                                ),
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
