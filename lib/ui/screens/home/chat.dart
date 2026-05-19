import 'package:botroad/bd/messages.dart';
import 'package:botroad/models/conversionModel.dart';
import 'package:botroad/ui/widgets/conversations.dart';
import 'package:botroad/ui/widgets/messageInput.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final List<ChatMessageModel> msgs = messages;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final spacing = height / 20;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3B44)),
        title: Text(
          'chat_title'.tr,
          style: const TextStyle(
            color: Color(0xFF2D3B44),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Credits : 8',
                style: TextStyle(color: Color(0xFF2D3B44), fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body:
          msgs.isEmpty
              ? _suggestionsScreen(height, spacing)
              : ConversationWidget(messages: msgs),
      bottomSheet: MessageInput(
        controller: TextEditingController(),
        onSend: () {},
      ),
    );
  }

  Widget _suggestionsScreen(double height, double spacing) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [Image.asset(Assets.logo, height: height / 4.5)],
            ),
          ),
          SizedBox(height: spacing),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Suggestion(
                  title: 'chat_suggestion_route'.tr,
                  subtitle: 'chat_suggestion_route_example'.tr,
                ),
                const SizedBox(height: 16),
                Suggestion(
                  title: 'chat_suggestion_destination'.tr,
                  subtitle: 'chat_suggestion_destination_example'.tr,
                ),
                const SizedBox(height: 16),
                Suggestion(
                  title: 'chat_suggestion_place'.tr,
                  subtitle: 'chat_suggestion_place_example'.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Suggestion extends StatelessWidget {
  final String title;
  final String subtitle;

  const Suggestion({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
