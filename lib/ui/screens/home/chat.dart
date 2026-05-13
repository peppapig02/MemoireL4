import 'package:botroad/bd/messages.dart';
import 'package:botroad/models/conversionModel.dart';
import 'package:botroad/ui/widgets/conversations.dart';
import 'package:botroad/ui/widgets/messageInput.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});
  final List<ChatMessageModel> msgs = messages;
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double spacing = height / 20;
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
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Color(0xFF2D3B44),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          RichText(
            text: const TextSpan(
              text: 'Crédits : ',
              style: TextStyle(color: Color(0xFF2D3B44), fontSize: 16),
              children: [
                TextSpan(
                  text: '8',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3B44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Le body depend de si la conversation est vide ou pas
      body:
          msgs.isEmpty
              ? SugestionsScreen(height, spacing)
              : ConversationWidget(messages: msgs),
      bottomSheet: MessageInput(
        controller: TextEditingController(),
        onSend: () {
          // Handle send action
        },
      ),
    );
  }

  Widget SugestionsScreen(double height, double spacing) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Center(
            child: Column(
              children: [Image.asset(Assets.logo, height: height / 4.5)],
            ),
          ),

          SizedBox(height: spacing),

          // Suggestion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: const [
                Suggestion(
                  title: 'Demande à l’IA ta route',
                  subtitle: '(Je veux aller à la plage)',
                ),
                SizedBox(height: 16),
                Suggestion(
                  title: 'Décrivez ou vous voulez aller',
                  subtitle: '(Je veux aller boire une bière)',
                ),
                SizedBox(height: 16),
                Suggestion(
                  title: 'Parlez brève d’un endroit',
                  subtitle: '(Je souhaite visiter un zoo)',
                ),
              ],
            ),
          ),

          // const Spacer(),

          // Input field
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
        color: Color(0xFFE9EBF1),
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
