// File: lib/chats/requested.dart
import 'package:chat_messaging_firebase/controller/chat_controller.dart';
import 'package:chat_messaging_firebase/model/friend_request.dart';
import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:chat_messaging_firebase/utils/common_search_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Requested extends StatelessWidget {
  const Requested({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFf5fafb),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.appBarIcon,
          ),
        ),
        title: const Text(
          'Friend Requests',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            title: Text(
              "Requests".toUpperCase(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CommonSearchField(
              hintText: 'Search',
              onChanged: (query) {
                // chatController.searchFriendRequests(query);
              },
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Obx(
              () => chatController.friendRequests.isEmpty
                  ? const Center(
                      child: Text(
                        'No friend requests',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: chatController.friendRequests.length,
                      itemBuilder: (context, index) {
                        final request = chatController.friendRequests[index];
                        return Column(
                          children: [
                            ListTile(
                              dense: true,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  request.senderImage,
                                  fit: BoxFit.cover,
                                  height: 50,
                                  width: 50,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 50),
                                ),
                              ),
                              title: Text(
                                request.senderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: const Text(
                                "View Profile",
                                style: TextStyle(color: bgColor1),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 33,
                                    child: TextButton(
                                      onPressed: () => chatController.acceptFriendRequest(
                                        request.id,
                                        request.senderId,
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: thirdColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Accept',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 33,
                                    child: TextButton(
                                      onPressed: () =>
                                          chatController.rejectFriendRequest(request.id),
                                      style: TextButton.styleFrom(
                                        backgroundColor: secondaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              endIndent: 28,
                              indent: 80,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}