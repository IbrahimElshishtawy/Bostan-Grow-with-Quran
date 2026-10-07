enum MessageSender {
  user,
  assistant,
}

class AiChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String? quranReference; // e.g. [سورة البقرة: 255]

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.quranReference,
  });

  bool get isUser => sender == MessageSender.user;
}
