import 'package:chat_messaging_firebase/chats/create_group.dart';
import 'package:chat_messaging_firebase/controller/chat_controller.dart';
import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:chat_messaging_firebase/utils/common_search_field.dart';
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddNewChats extends StatelessWidget {
  AddNewChats({super.key});

  final ChatController chatController = Get.find<ChatController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(bottom: context.devicePaddingBottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const ListTile(
              dense: true,
              title: Text(
                "New Chat",
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CommonSearchField(
                hintText: 'Search',
                onChanged: (query) => chatController.searchUsers(query),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Get.to(() => CreateGroup());
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    'CREATE GROUP CHAT',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Users list for adding friends (excluding existing friends and sent requests)
            Expanded(
              child: Obx(
                () {
                  // Filter out users who are already friends or have pending sent friend requests
                  final availableUsers = chatController.allUsers.where((user) {
                    // Exclude current user
                    if (user.id == chatController.currentUserId) return false;
                    // Exclude users who are already friends (in chatUsers)
                    final isFriend = chatController.chatUsers.any((friend) => friend.id == user.id);
                    // Exclude users with pending sent friend requests
                    final hasSentRequest = chatController.sentFriendRequests.any((request) => request.receiverId == user.id);
                    return !isFriend && !hasSentRequest;
                  }).toList();

                  return availableUsers.isEmpty
                      ? const Center(
                          child: Text(
                            'No new users to add',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: availableUsers.length,
                          itemBuilder: (context, index) {
                            final user = availableUsers[index];
                            return ListTile(
                              dense: true,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  user.image,
                                  fit: BoxFit.cover,
                                  height: 50,
                                  width: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset('assets/images/default_avatar.png'),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  if (user.isOnline)
                                    const Icon(Icons.circle, color: Colors.green, size: 10),
                                ],
                              ),
                              subtitle: Text(
                                user.lastMessage.isEmpty ? 'No messages' : user.lastMessage,
                              ),
                              trailing: SizedBox(
                                height: 33,
                                child: TextButton(
                                  onPressed: () async {
                                    await chatController.sendFriendRequest(
                                      user.id,
                                      user.name,
                                      user.image,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: thirdColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Friend',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}