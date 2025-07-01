// Chat model class
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String id; // chatRoomId for chats, userId for users in AddNewChats
  final String name;
  final String image;
  final String lastMessage;
  final String timestamp;
  final int msgCount;
  final bool isOnline;
  final bool isGroupChat;
  final List<String>? members;

  ChatUser({
    required this.id,
    required this.name,
    required this.image,
    required this.lastMessage,
    required this.timestamp,
    this.msgCount = 0,
    this.isOnline = false,
    this.isGroupChat = false,
    this.members,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatUser(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['profileImage'] ?? dummyProfile,
      lastMessage: data['lastMessage'] ?? '',
      timestamp: data['lastMessageTime']?.toString() ?? '',
      msgCount: data['unreadCount'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      isGroupChat: data['isGroupChat'] ?? false,
      members: data['members'] != null ? List<String>.from(data['members']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'profileImage': image,
      'lastMessage': lastMessage,
      'lastMessageTime': timestamp,
      'unreadCount': msgCount,
      'isOnline': isOnline,
      'isGroupChat': isGroupChat,
      'members': members,
    };
  }
}