import 'package:chat_messaging_firebase/chats/one_to_one_screen.dart';
import 'package:chat_messaging_firebase/controller/chat_controller.dart';
import 'package:chat_messaging_firebase/model/chat_user.dart';
import 'package:chat_messaging_firebase/utils/app_colors.dart';
import 'package:chat_messaging_firebase/utils/common_bottom.dart';
import 'package:chat_messaging_firebase/utils/common_search_field.dart';
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateGroup extends StatefulWidget {
  CreateGroup({super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final ChatController chatController = Get.find<ChatController>();
  final TextEditingController groupNameController = TextEditingController();
  final RxList<ChatUser> selectedUsers = <ChatUser>[].obs;
  final RxString searchQuery = ''.obs;
  final RxList<ChatUser> filteredUsers = <ChatUser>[].obs;

  void toggleUserSelection(ChatUser user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'New Group Chat',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: FutureBuilder<List<ChatUser>>(
          future: chatController.getAvailableUsersForGroup(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading users',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => setState(() {}),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No friends available to add'),
                    TextButton(
                      onPressed: () => Get.toNamed('/addFriends'),
                      child: const Text(
                        'Add Friends',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ],
                ),
              );
            }

            final availableUsers = snapshot.data!;
            if (searchQuery.value.isEmpty) {
              filteredUsers.value = availableUsers;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: context.devicePaddingBottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: CommonSearchField(
                      hintText: 'Group Chat Name',
                      controller: groupNameController,
                      onChanged: (value) {},
                    ),
                  ),

                  // Selected users section
                  Obx(() => selectedUsers.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Selected (${selectedUsers.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = selectedUsers[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundImage: user.image.startsWith('http')
                                                    ? NetworkImage(user.image)
                                                    : AssetImage(user.image) as ImageProvider,
                                                onBackgroundImageError: (_, __) => const AssetImage(dummyProfile),
                                              ),
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: GestureDetector(
                                                  onTap: () => toggleUserSelection(user),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: Colors.white, width: 2),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              user.name,
                                              style: const TextStyle(fontSize: 10),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Divider(
                              endIndent: 16,
                              indent: 16,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ],
                        )
                      : const SizedBox.shrink()),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: CommonSearchField(
                      hintText: 'Search Users',
                      onChanged: (query) {
                        searchQuery.value = query;
                        filteredUsers.value = query.isEmpty
                            ? availableUsers
                            : availableUsers
                                .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
                                .toList();
                      },
                    ),
                  ),

                  // Available users list
                  Obx(() => Expanded(
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return Obx(() {
                              final isSelected = selectedUsers.contains(user);
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundImage: user.image.startsWith('http')
                                      ? NetworkImage(user.image)
                                      : AssetImage(user.image) as ImageProvider,
                                  onBackgroundImageError: (_, __) => const AssetImage(dummyProfile),
                                ),
                                title: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? primaryColor : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  user.lastMessage.isEmpty ? 'No recent message' : user.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: GestureDetector(
                                  onTap: () => toggleUserSelection(user),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 2,
                                        color: isSelected ? primaryColor : Colors.grey.shade400,
                                      ),
                                      color: isSelected ? primaryColor : Colors.transparent,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                onTap: () => toggleUserSelection(user),
                              );
                            });
                          },
                        ),
                      )),

                  // Create group button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Obx(() => CommonButton(
                            btnText: selectedUsers.isEmpty 
                                ? 'Create Group' 
                                : 'Create Group (${selectedUsers.length})',
                            onClick: () async {
                              final groupName = groupNameController.text.trim();
                              if (groupName.isEmpty) {
                                Get.snackbar('Error', 'Please enter a group name');
                                return;
                              }
                              if (selectedUsers.isEmpty) {
                                Get.snackbar('Error', 'Please select at least one member');
                                return;
                              }
                              
                              // Show loading
                              Get.dialog(
                                const Center(child: CircularProgressIndicator()),
                                barrierDismissible: false,
                              );

                              final groupChatId = await chatController.createGroupChat(
                                groupName: groupName,
                                memberIds: selectedUsers.map((user) => user.id).toList(),
                                groupImage: 'assets/images/group_image.png',
                              );

                              // Close loading dialog
                              Get.back();

                              if (groupChatId != null) {
                                Get.off(
                                  () => OneToOneChatScreen(),
                                  arguments: {
                                    'chatRoomId': groupChatId,
                                    'receiverName': groupName,
                                    'isGroupChat': true,
                                    'receiverImage': 'assets/images/group_image.png',
                                    'members': selectedUsers.map((user) => user.id).toList(),
                                  },
                                );
                              } else {
                                Get.snackbar('Error', 'Failed to create group chat');
                              }
                            },
                          )),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}