import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: const Color(0xFFF6F7FB),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // Zone de texte multilignes
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EBF1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,

                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: const Color(0xFFE9EBF1),
                  isDense: true,
                  hintText: 'Décrivez moi le lieu',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton d’envoi
          GestureDetector(
            onTap: onSend,
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1F3A53),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
