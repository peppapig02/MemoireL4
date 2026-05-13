import 'package:botroad/models/conversionModel.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

class ConversationWidget extends StatelessWidget {
  final List<ChatMessageModel> messages;

  const ConversationWidget({Key? key, required this.messages})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
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
              color: message.isUser ? AppColors.primary : Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.sender,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: message.isUser ? Colors.white : Colors.grey[800],
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
