import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String text;
  final String senderId;
  final Timestamp timestamp;

  ChatMessage({required this.text, required this.senderId, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'text': text,
        'senderId': senderId,
        'timestamp': timestamp,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'],
        senderId: json['senderId'],
        timestamp: json['timestamp'],
      );
}
