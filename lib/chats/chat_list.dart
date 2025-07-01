// Updated ChatsList widget
import 'package:chat_messaging_firebase/chats/add_new_chats.dart';
import 'package:chat_messaging_firebase/chats/one_to_one_screen.dart';
import 'package:chat_messaging_firebase/chats/requested.dart';
import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:chat_messaging_firebase/utils/common_search_field.dart';
import 'package:chat_messaging_firebase/controller/chat_controller.dart';
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ChatsList extends StatelessWidget {
  const ChatsList({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.put(ChatController());

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.devicePaddingTop),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListTile(
              dense: true,
              title: Text(
                "Chats".toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              trailing: SizedBox(
                height: 34,
                child: Obx(
                  () => TextButton(
                    onPressed: () => Get.to(() => Requested()),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: bgColor1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Requests ',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                            ),
                          ),
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: bgColor,
                            child: Center(
                              child: Text(
                                "${chatController.requestCount.value}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: CommonSearchField(
                    hintText: 'Search',
                    onChanged: (value) => chatController.searchUsers(value),
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await chatController.fetchAllUsers();
                  Get.to(() => AddNewChats());
                },
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: primaryColor),
              ),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (chatController.chatUsers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No chats found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => chatController.refreshChats(),
                child: ListView.builder(
                  itemCount: chatController.chatUsers.length,
                  itemBuilder: (context, index) {
                    final chatUser = chatController.chatUsers[index];
                    return ListTile(
                      dense: true,
                      onTap: () {
                        if (chatUser.msgCount > 0) {
                          chatController.markMessagesAsRead(chatUser.id);
                        }
                        Get.to(
                          () => OneToOneChatScreen(),
                          arguments: {
                            'chatRoomId': chatUser.id,
                            'receiverName': chatUser.name,
                            'isGroupChat': chatUser.isGroupChat,
                            'members': chatUser.members,
                          },
                        );
                      },
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child:
                                chatUser.image.startsWith('http')
                                    ? Image.network(
                                      chatUser.image,
                                      fit: BoxFit.cover,
                                      height: 50,
                                      width: 50,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                size: 50,
                                              ),
                                    )
                                    : Image.asset(
                                      chatUser.image,
                                      fit: BoxFit.cover,
                                      height: 50,
                                      width: 50,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                size: 50,
                                              ),
                                    ),
                          ),
                          if (!chatUser.isGroupChat && chatUser.isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 16,
                                width: 16,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chatUser.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    chatUser.msgCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (chatUser.msgCount > 0)
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: bgColor,
                              child: Center(
                                child: Text(
                                  chatUser.msgCount > 99
                                      ? '99+'
                                      : chatUser.msgCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        chatUser.lastMessage.isEmpty
                            ? "No messages yet"
                            : chatUser.lastMessage,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chatUser.timestamp,
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          if (chatUser.isGroupChat)
                            Text(
                              "${chatUser.members?.length ?? 0} members",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 8,
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color:
                                      chatUser.isOnline
                                          ? Colors.green
                                          : Colors.grey,
                                  size: 8,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  chatUser.isOnline ? 'Online' : 'Offline',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
