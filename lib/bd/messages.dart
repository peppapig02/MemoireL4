import 'package:botroad/models/conversionModel.dart';

List<ChatMessageModel> messages = [
  ChatMessageModel(
    sender: "Wapi",
    message:
        "Bonjour Moïse Comment allez-vous aujourd'hui et comment je peux faire pour vous aider ?",
    isUser: false,
  ),
  ChatMessageModel(
    sender: "Moïse",
    message: "Moi je veux bien et toi ?",
    isUser: true,
  ),
  ChatMessageModel(
    sender: "Wapi",
    message:
        "Super de te savoir en bonne santé moi je suis une ia je veux toujours bien. Dit moi plutôt ou tu veux aller aujourd'hui comme ça je t'aide à retrouver",
    isUser: false,
  ),
  ChatMessageModel(
    sender: "Moïse",
    message: "Décrivez moi le lieu",
    isUser: true,
  ),
];
