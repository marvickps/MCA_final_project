class Message {
  final String id;
  String text;
  final bool isUser;
  final DateTime timestamp;
  dynamic additionalData; // For analytics JSON or other data

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.additionalData,
  });
}
