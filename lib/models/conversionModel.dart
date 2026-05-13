class ChatMessageModel {
  final String sender;
  final String message;
  final bool isUser;

  ChatMessageModel({
    required this.sender,
    required this.message,
    required this.isUser,
  });
}
