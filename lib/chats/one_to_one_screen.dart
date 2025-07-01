import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messaging_firebase/controller/chat_controller.dart';
import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OneToOneChatScreen extends StatefulWidget {
  OneToOneChatScreen({super.key});

  @override
  State<OneToOneChatScreen> createState() => _OneToOneChatScreenState();
}

class _OneToOneChatScreenState extends State<OneToOneChatScreen> {
  final Map<String, dynamic> args = Get.arguments;
  final TextEditingController messageController = TextEditingController();
  final ChatController chatController = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String chatRoomId = args['chatRoomId'];
      if (chatRoomId.isNotEmpty) {
        chatController.markMessagesAsRead(chatRoomId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String chatRoomId = args['chatRoomId'] ?? '';
    final String receiverName = args['receiverName'] ?? 'Unknown';
    final bool isGroupChat = args['isGroupChat'] ?? false;
    final String receiverImage = args['receiverImage'] ?? '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
            onPressed: () => Get.back(),
          ),
          titleSpacing: 0,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CircleAvatar(
              //   radius: 20,
              //   backgroundColor: Colors.grey[300],
              //   backgroundImage: receiverImage.isNotEmpty && 
              //       !receiverImage.startsWith('assets/') && 
              //       Uri.tryParse(receiverImage) != null
              //       ? NetworkImage(receiverImage)
              //       : null,
              //   child: (receiverImage.isEmpty || 
              //          receiverImage.startsWith('assets/') || 
              //          Uri.tryParse(receiverImage) == null)
              //       ? const Icon(Icons.person, color: Colors.white)
              //       : null,
              // ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiverName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isGroupChat && args['members'] != null)
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_getReceiverId())
                            .snapshots(),
                        builder: (context, snapshot) {
                          // Check if snapshot has data AND the document exists
                          if (!snapshot.hasData || 
                              !snapshot.data!.exists) {
                            return const Text(
                              "Offline",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            );
                          }

                          try {
                            // Safely get the isOnline field
                            Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
                            bool isOnline = data?['isOnline'] ?? false;

                            return Text(
                              isOnline ? "Online" : "Offline",
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Error getting online status: $e');
                            return const Text(
                              "Offline",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_outlined, size: 18),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: chatController.getMessages(chatRoomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryColor));
                  }
                  if (snapshot.hasError) {
                    debugPrint('Stream error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading messages',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 4),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final String text = message['text'] ?? '';
                      final bool isMyMessage = message['senderId'] == chatController.currentUserId;
                      
                      // Safely handle optional fields that might not exist
                      final bool isRead = message.containsKey('isRead') ? (message['isRead'] ?? false) : false;
                      final bool isDelivered = message.containsKey('delivered') ? (message['delivered'] ?? false) : true;
                      
                      // Uncomment when you have the formatTimestamp method
                      // final String formattedTime = chatController.formatTimestamp(message['timestamp']);

                      return Align(
                        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isMyMessage ? primaryColor : bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Uncomment when you have the formatTimestamp method
                                  // Text(
                                  //   formattedTime,
                                  //   style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  // ),
                                  if (isMyMessage) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      isRead 
                                          ? Icons.done_all 
                                          : isDelivered 
                                              ? Icons.done_all 
                                              : Icons.access_time,
                                      color: isRead 
                                          ? secondaryColor 
                                          : isDelivered 
                                              ? Colors.grey[600] 
                                              : Colors.grey,
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 12,
                right: 12,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 0.5),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: "Type a message...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: thirdColor1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: thirdColor1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: thirdColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (messageController.text.trim().isNotEmpty && chatRoomId.isNotEmpty) {
                            chatController.sendMessage(chatRoomId, messageController.text.trim());
                            messageController.clear();
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to safely get receiver ID
  String? _getReceiverId() {
    final members = args['members'];
    if (members == null || members.isEmpty) return null;
    
    try {
      return members.firstWhere(
        (id) => id != chatController.currentUserId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('Error getting receiver ID: $e');
      return null;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}