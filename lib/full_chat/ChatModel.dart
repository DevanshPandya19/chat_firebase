import 'Message.dart';

class ChatModel {
  final String chatId;
  final List<Message> messages;

  ChatModel({
    required this.chatId,
    required this.messages,
  });
}
