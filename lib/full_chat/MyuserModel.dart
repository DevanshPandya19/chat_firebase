import 'ChatModel.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String imgurl;
  final String status;
  final List<ChatModel> chats;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.imgurl,
    required this.status,
    required this.chats,
  });
}

