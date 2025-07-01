import 'package:chat_messaging_firebase/model/chat_user.dart';
import 'package:chat_messaging_firebase/model/friend_request.dart';
import 'package:chat_messaging_firebase/utils/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var chatUsers = <ChatUser>[].obs;
  var filteredChatUsers = <ChatUser>[].obs;
  var allUsers = <ChatUser>[].obs;
  var friendRequests = <FriendRequest>[].obs; // Incoming requests
  var sentFriendRequests = <FriendRequest>[].obs; // Add this for sent requests
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var requestCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChatUsers();
    fetchAllUsers();
    fetchFriendRequests();
    fetchSentFriendRequests();
    listenToUserPresence();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  // NEW: Create Group Chat Method
  Future<String?> createGroupChat({
    required String groupName,
    required List<String> memberIds,
    String? groupImage,
  }) async {
    if (currentUserId == null || memberIds.isEmpty) {
      Get.snackbar('Error', 'Cannot create group chat');
      return null;
    }

    try {
      // Add current user to the members list
      List<String> allMembers = [currentUserId!, ...memberIds];

      // Remove duplicates
      allMembers = allMembers.toSet().toList();

      // Create unread counts for all members
      Map<String, dynamic> unreadCounts = {};
      for (String memberId in allMembers) {
        unreadCounts[memberId] = 0;
      }

      // Create the group chat document
      DocumentReference groupChatRef = await _firestore
          .collection('chatRooms')
          .add({
            'groupName': groupName,
            'groupImage': groupImage ?? 'assets/images/group_image.png',
            'participants': allMembers,
            'isGroupChat': true,
            'createdBy': currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': 'Group created',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadCounts': unreadCounts,
          });

      // Add initial system message
      await _firestore
          .collection('chatRooms')
          .doc(groupChatRef.id)
          .collection('messages')
          .add({
            'text': 'Group "$groupName" was created',
            'senderId': 'system',
            'timestamp': FieldValue.serverTimestamp(),
            'delivered': true,
            'isSystemMessage': true,
          });

      // Refresh chat users to show the new group
      await fetchChatUsers();

      Get.snackbar('Success', 'Group chat created successfully');
      return groupChatRef.id;
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      Get.snackbar('Error', 'Failed to create group chat');
      return null;
    }
  }

  // NEW: Get Available Users for Group Creation (friends only)
  Future<List<ChatUser>> getAvailableUsersForGroup() async {
    if (currentUserId == null) return [];

    try {
      // Get all chat rooms where current user is a participant
      QuerySnapshot chatRoomsSnapshot =
          await _firestore
              .collection('chatRooms')
              .where('participants', arrayContains: currentUserId)
              .where('isGroupChat', isEqualTo: false)
              .get();

      List<String> friendIds = [];

      // Extract friend IDs from individual chat rooms
      for (var doc in chatRoomsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> participants = List<String>.from(
          data['participants'] ?? [],
        );

        for (String participantId in participants) {
          if (participantId != currentUserId &&
              !friendIds.contains(participantId)) {
            friendIds.add(participantId);
          }
        }
      }

      // Fetch user details for all friends
      List<ChatUser> availableUsers = [];
      for (String friendId in friendIds) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(friendId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          availableUsers.add(
            ChatUser(
              id: friendId,
              name: userData['name'] ?? 'Unknown User',
              image: userData['profileImage'] ?? dummyProfile,
              lastMessage: '',
              timestamp: '',
              msgCount: 0,
              isOnline: userData['isOnline'] ?? false,
              isGroupChat: false,
            ),
          );
        }
      }

      return availableUsers;
    } catch (e) {
      debugPrint('Error fetching available users: $e');
      return [];
    }
  }

  // NEW: Add Member to Existing Group
  Future<void> addMemberToGroup(String groupChatId, String userId) async {
    if (currentUserId == null) return;

    try {
      // Get current group data
      DocumentSnapshot groupDoc =
          await _firestore.collection('chatRooms').doc(groupChatId).get();
      if (!groupDoc.exists) return;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<String> currentMembers = List<String>.from(
        groupData['participants'] ?? [],
      );

      if (currentMembers.contains(userId)) {
        Get.snackbar('Info', 'User is already in the group');
        return;
      }

      // Add new member
      currentMembers.add(userId);

      // Update unread counts
      Map<String, dynamic> unreadCounts = Map<String, dynamic>.from(
        groupData['unreadCounts'] ?? {},
      );
      unreadCounts[userId] = 0;

      // Update group document
      await _firestore.collection('chatRooms').doc(groupChatId).update({
        'participants': currentMembers,
        'unreadCounts': unreadCounts,
      });

      // Add system message
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      String userName =
          userDoc.exists
              ? (userDoc.data() as Map<String, dynamic>)['name'] ??
                  'Unknown User'
              : 'Unknown User';

      await _firestore
          .collection('chatRooms')
          .doc(groupChatId)
          .collection('messages')
          .add({
            'text': '$userName was added to the group',
            'senderId': 'system',
            'timestamp': FieldValue.serverTimestamp(),
            'delivered': true,
            'isSystemMessage': true,
          });

      await fetchChatUsers();
      Get.snackbar('Success', 'Member added to group');
    } catch (e) {
      debugPrint('Error adding member to group: $e');
      Get.snackbar('Error', 'Failed to add member');
    }
  }

  // NEW: Remove Member from Group
  Future<void> removeMemberFromGroup(String groupChatId, String userId) async {
    if (currentUserId == null) return;

    try {
      // Get current group data
      DocumentSnapshot groupDoc =
          await _firestore.collection('chatRooms').doc(groupChatId).get();
      if (!groupDoc.exists) return;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<String> currentMembers = List<String>.from(
        groupData['participants'] ?? [],
      );

      if (!currentMembers.contains(userId)) {
        Get.snackbar('Info', 'User is not in the group');
        return;
      }

      // Remove member
      currentMembers.remove(userId);

      // Update unread counts
      Map<String, dynamic> unreadCounts = Map<String, dynamic>.from(
        groupData['unreadCounts'] ?? {},
      );
      unreadCounts.remove(userId);

      // Update group document
      await _firestore.collection('chatRooms').doc(groupChatId).update({
        'participants': currentMembers,
        'unreadCounts': unreadCounts,
      });

      // Add system message
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      String userName =
          userDoc.exists
              ? (userDoc.data() as Map<String, dynamic>)['name'] ??
                  'Unknown User'
              : 'Unknown User';

      await _firestore
          .collection('chatRooms')
          .doc(groupChatId)
          .collection('messages')
          .add({
            'text': '$userName was removed from the group',
            'senderId': 'system',
            'timestamp': FieldValue.serverTimestamp(),
            'delivered': true,
            'isSystemMessage': true,
          });

      await fetchChatUsers();
      Get.snackbar('Success', 'Member removed from group');
    } catch (e) {
      debugPrint('Error removing member from group: $e');
      Get.snackbar('Error', 'Failed to remove member');
    }
  }

  // NEW: Leave Group
  Future<void> leaveGroup(String groupChatId) async {
    if (currentUserId == null) return;
    await removeMemberFromGroup(groupChatId, currentUserId!);
  }

  // NEW: Update Group Info
  Future<void> updateGroupInfo(
    String groupChatId, {
    String? groupName,
    String? groupImage,
  }) async {
    if (currentUserId == null) return;

    try {
      Map<String, dynamic> updates = {};
      if (groupName != null) updates['groupName'] = groupName;
      if (groupImage != null) updates['groupImage'] = groupImage;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('chatRooms')
            .doc(groupChatId)
            .update(updates);
        await fetchChatUsers();
        Get.snackbar('Success', 'Group info updated');
      }
    } catch (e) {
      debugPrint('Error updating group info: $e');
      Get.snackbar('Error', 'Failed to update group info');
    }
  }

  // Existing methods remain the same...
  Future<void> fetchAllUsers() async {
    try {
      debugPrint('Fetching all users from Firestore');
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      allUsers.value =
          userSnapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
            debugPrint('User found: ${doc.id}, Data: ${doc.data()}');
            return ChatUser.fromFirestore(doc);
          }).toList();

      if (searchQuery.value.isEmpty) {
        filteredChatUsers.value = allUsers;
      }
      debugPrint('Fetched ${allUsers.length} users');
    } catch (e) {
      debugPrint('Error fetching users: $e');
      Get.snackbar('Error', 'Failed to load users');
    }
  }

  Future<void> fetchChatUsers() async {
    try {
      isLoading.value = true;
      if (currentUserId == null) return;

      QuerySnapshot chatRoomsSnapshot =
          await _firestore
              .collection('chatRooms')
              .where('participants', arrayContains: currentUserId)
              .orderBy('lastMessageTime', descending: true)
              .get();

      List<ChatUser> users = [];
      for (var doc in chatRoomsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<String> participants = List<String>.from(
          data['participants'] ?? [],
        );
        List<String> otherParticipants =
            participants.where((id) => id != currentUserId).toList();

        if (otherParticipants.isNotEmpty) {
          if (data['isGroupChat'] == true) {
            users.add(
              ChatUser(
                id: doc.id,
                name: data['groupName'] ?? 'Group Chat',
                image: data['groupImage'] ?? 'assets/images/group_image.png',
                lastMessage: data['lastMessage'] ?? '',
                timestamp: _formatTimestamp(data['lastMessageTime']),
                msgCount: data['unreadCounts']?[currentUserId] ?? 0,
                isOnline: false,
                isGroupChat: true,
                members: participants,
              ),
            );
          } else {
            String otherUserId = otherParticipants.first;
            DocumentSnapshot userDoc =
                await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists) {
              Map<String, dynamic> userData =
                  userDoc.data() as Map<String, dynamic>;
              users.add(
                ChatUser(
                  id: doc.id,
                  name: userData['name'] ?? 'Unknown User',
                  image: userData['profileImage'] ?? dummyProfile,
                  lastMessage: data['lastMessage'] ?? '',
                  timestamp: _formatTimestamp(data['lastMessageTime']),
                  msgCount: data['unreadCounts']?[currentUserId] ?? 0,
                  isOnline: userData['isOnline'] ?? false,
                  isGroupChat: false,
                ),
              );
            }
          }
        }
      }

      chatUsers.value = users;
      if (searchQuery.value.isEmpty) {
        filteredChatUsers.value = users;
      }
    } catch (e) {
      debugPrint('Error fetching chat users: $e');
      Get.snackbar('Error', 'Failed to load chats');
    } finally {
      isLoading.value = false;
    }
  }

  // Rest of your existing methods remain unchanged...
  Future<void> sendFriendRequest(
    String receiverId,
    String receiverName,
    String receiverImage,
  ) async {
    if (currentUserId == null) return;
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      await _firestore.collection('friendRequests').add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'senderName': userData['name'] ?? 'User',
        'senderImage': userData['profileImage'] ?? dummyProfile,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await fetchFriendRequests();
      await fetchSentFriendRequests();
      Get.snackbar('Success', 'Friend request sent');
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      Get.snackbar('Error', 'Failed to send friend request');
    }
  }

  Future<void> fetchFriendRequests() async {
    if (currentUserId == null) return;
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('friendRequests')
              .where('receiverId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();

      friendRequests.value =
          snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList();
      requestCount.value = friendRequests.length;
      debugPrint('Fetched ${friendRequests.length} friend requests');
    } catch (e) {
      debugPrint('Error fetching friend requests: $e');
      Get.snackbar('Error', 'Failed to load friend requests');
    }
  }

  Future<void> fetchSentFriendRequests() async {
    if (currentUserId == null) return;
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('friendRequests')
              .where('senderId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();

      sentFriendRequests.value =
          snapshot.docs.map((doc) => FriendRequest.fromFirestore(doc)).toList();
      debugPrint('Fetched ${sentFriendRequests.length} sent friend requests');
    } catch (e) {
      debugPrint('Error fetching sent friend requests: $e');
      Get.snackbar('Error', 'Failed to load sent friend requests');
    }
  }

  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'accepted',
      });

      await _firestore.collection('chatRooms').add({
        'participants': [currentUserId, senderId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isGroupChat': false,
        'unreadCounts': {currentUserId!: 0, senderId: 0},
      });

      await fetchFriendRequests();
      await fetchChatUsers();
      Get.snackbar('Success', 'Friend request accepted');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      Get.snackbar('Error', 'Failed to accept friend request');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
      });
      await fetchFriendRequests();
      Get.snackbar('Success', 'Friend request rejected');
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      Get.snackbar('Error', 'Failed to reject friend request');
    }
  }

  Future<void> sendMessage(String chatRoomId, String message) async {
    if (currentUserId == null || message.trim().isEmpty) return;
    try {
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
            'text': message,
            'senderId': currentUserId,
            'timestamp': FieldValue.serverTimestamp(),
            'delivered': false,
          });

      DocumentSnapshot chatRoomDoc =
          await _firestore.collection('chatRooms').doc(chatRoomId).get();
      if (!chatRoomDoc.exists) {
        debugPrint('Chat room not found');
        return;
      }

      Map<String, dynamic> chatRoomData =
          chatRoomDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(
        chatRoomData['participants'] ?? [],
      );

      Map<String, dynamic> unreadCounts = {currentUserId!: 0};
      for (String participantId in participants) {
        if (participantId != currentUserId) {
          unreadCounts[participantId] = FieldValue.increment(1);
        }
      }

      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCounts': unreadCounts,
      });

      await fetchChatUsers();
    } catch (e) {
      debugPrint('Error sending message: $e');
      Get.snackbar('Error', 'Failed to send message');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'text': data['text'] ?? '',
                  'senderId': data['senderId'] ?? '',
                  'timestamp': data['timestamp'],
                  'delivered': data['delivered'] ?? false,
                  'isRead': data['isRead'] ?? false,
                  'isSystemMessage': data['isSystemMessage'] ?? false,
                };
              }).toList(),
        );
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'unreadCounts.$currentUserId': 0,
      });

      QuerySnapshot messages =
          await _firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .collection('messages')
              .where('senderId', isNotEqualTo: currentUserId)
              .where('delivered', isEqualTo: false)
              .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'delivered': true});
      }

      int index = chatUsers.indexWhere((user) => user.id == chatRoomId);
      if (index != -1) {
        chatUsers[index] = ChatUser(
          id: chatUsers[index].id,
          name: chatUsers[index].name,
          image: chatUsers[index].image,
          lastMessage: chatUsers[index].lastMessage,
          timestamp: chatUsers[index].timestamp,
          msgCount: 0,
          isOnline: chatUsers[index].isOnline,
          isGroupChat: chatUsers[index].isGroupChat,
          members: chatUsers[index].members,
        );
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void listenToUserPresence() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          String userId = change.doc.id;
          bool isOnline = change.doc.data()?['isOnline'] ?? false;

          int index = chatUsers.indexWhere((user) => user.id == userId);
          if (index != -1) {
            chatUsers[index] = ChatUser(
              id: chatUsers[index].id,
              name: chatUsers[index].name,
              image: chatUsers[index].image,
              lastMessage: chatUsers[index].lastMessage,
              timestamp: chatUsers[index].timestamp,
              msgCount: chatUsers[index].msgCount,
              isOnline: isOnline,
              isGroupChat: chatUsers[index].isGroupChat,
              members: chatUsers[index].members,
            );
          }

          int allUsersIndex = allUsers.indexWhere((user) => user.id == userId);
          if (allUsersIndex != -1) {
            allUsers[allUsersIndex] = ChatUser(
              id: allUsers[allUsersIndex].id,
              name: allUsers[allUsersIndex].name,
              image: allUsers[allUsersIndex].image,
              lastMessage: allUsers[allUsersIndex].lastMessage,
              timestamp: allUsers[allUsersIndex].timestamp,
              msgCount: allUsers[allUsersIndex].msgCount,
              isOnline: isOnline,
              isGroupChat: allUsers[allUsersIndex].isGroupChat,
              members: allUsers[allUsersIndex].members,
            );
          }
        }
      }
      if (searchQuery.value.isNotEmpty) {
        searchUsers(searchQuery.value);
      }
    });
  }

  void searchUsers(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredChatUsers.value = chatUsers;
    } else {
      filteredChatUsers.value =
          chatUsers
              .where(
                (user) => user.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    }
  }

  Future<void> fetchRequestCount() async {
    if (currentUserId == null) return;
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('friendRequests')
              .where('receiverId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();
      requestCount.value = snapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching request count: $e');
    }
  }

  Future<void> updateUserOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      return timestamp;
    } else {
      return '';
    }
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> refreshChats() async {
    await fetchChatUsers();
    await fetchRequestCount();
  }

  @override
  void onClose() {
    updateUserOnlineStatus(false);
    super.onClose();
  }
}
