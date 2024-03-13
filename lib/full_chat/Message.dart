class Message {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String imageUrl;
  final String documentUrl;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.imageUrl,
    required this.documentUrl,
    required this.createdAt,
  });
}
