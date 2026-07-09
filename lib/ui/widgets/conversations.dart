import 'package:botroad/models/conversionModel.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

class ConversationWidget extends StatelessWidget {
  final List<ChatMessageModel> messages;

  const ConversationWidget({Key? key, required this.messages})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: message.isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                ...AppTokens.neumorphicRaised(intensity: 0.7),
                if (message.isUser)
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.sender,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        message.isUser ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  message.message,
                  style: TextStyle(
                    color:
                        message.isUser ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
