// lib/group_details_page.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/map.dart';
import 'notifications.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({super.key, required this.groupId, required this.groupName});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  bool _isComposing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessagesList()),
            if (_imageFile != null) _buildImagePreview(),
            _buildMessageComposer(context, theme, mediaQuery),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final memberCount = (data?['members'] as List?)?.length ?? 0;
                      return Text(
                        '$memberCount members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => _navigateToGroupDetails(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, size: 20, color: Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation by sending a message',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data() as Map<String, dynamic>;
            final previousMessage = index < messages.length - 1 
                ? messages[index + 1].data() as Map<String, dynamic>
                : null;
            
            return _buildMessageBubble(message, previousMessage);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, Map<String, dynamic>? previousMessage) {
    final bool isCurrentUser = message['sender_id'] == currentUser?.uid;
    final bool showAvatar = !isCurrentUser && 
        (previousMessage == null || previousMessage['sender_id'] != message['sender_id']);
    final bool showSenderName = !isCurrentUser && showAvatar;

    return Container(
      margin: EdgeInsets.only(
        bottom: 2,
        top: showAvatar ? 16 : 2,
        left: isCurrentUser ? 48 : 0,
        right: isCurrentUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            SizedBox(
              width: 32,
              child: showAvatar
                  ? _buildUserAvatar(message['sender_id'])
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser 
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showSenderName) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: _buildSenderName(message['sender_id']),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? AppColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isCurrentUser ? 18 : (showAvatar ? 4 : 18)),
                      topRight: Radius.circular(isCurrentUser ? (showAvatar ? 4 : 18) : 18),
                      bottomLeft: const Radius.circular(18),
                      bottomRight: const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message['image_url'] != null && 
                          (message['image_url'] as String).isNotEmpty)
                        _buildMessageImage(message['image_url']),
                      if (message['content'] != null && 
                          (message['content'] as String).isNotEmpty)
                        _buildMessageText(message['content'], isCurrentUser),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String senderId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final photoURL = userData?['photoURL'] as String?;
          
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color.fromARGB(255, 0, 0, 0)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: (photoURL != null && photoURL.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: photoURL,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          );
        }
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 16),
        );
      },
    );
  }

  Widget _buildSenderName(String senderId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final displayName = userData?['displayName'] ?? userData?['email'] ?? 'Unknown';
          
          return Text(
            displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMessageImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageText(String content, bool isCurrentUser) {
    return Text(
      content,
      style: TextStyle(
        color: isCurrentUser ? Colors.white : const Color(0xFF1A1A1A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: FileImage(_imageFile!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: () => setState(() => _imageFile = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(BuildContext context, ThemeData theme, MediaQueryData mediaQuery) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        mediaQuery.padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _pickImage,
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Color(0xFF6B7280),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: (_isComposing || _imageFile != null) 
                    ? AppColors.primary 
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: (_isComposing || _imageFile != null) ? _sendMessage : null,
                icon: Icon(
                  Icons.send_rounded,
                  color: (_isComposing || _imageFile != null) 
                      ? Colors.white 
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToGroupDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsPage(groupId: widget.groupId),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty && _imageFile == null) return;

    // Clear input immediately for better UX
    _messageController.clear();
    final tempImageFile = _imageFile;
    setState(() {
      _imageFile = null;
      _isComposing = false;
    });

    try {
      String? imageUrl;
      if (tempImageFile != null) {
        final fileName = DateTime.now().toIso8601String();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images/${widget.groupId}/$fileName');
        
        await storageRef.putFile(tempImageFile);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'sender_id': currentUser?.uid,
        'content': messageText,
        'image_url': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // Handle error - you might want to show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class GroupDetailsPage extends StatelessWidget {
  final String groupId;

  const GroupDetailsPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              ),
            );
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final members = (groupData['members'] as List<dynamic>).cast<String>();
          final bool isMember = members.contains(FirebaseAuth.instance.currentUser?.uid);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, groupData),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(context, groupData),
                      const SizedBox(height: 32),
                      _buildMembersSection(context, members),
                      const SizedBox(height: 32),
                      if (isMember) _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> groupData) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            groupData['name'] ?? 'Group Details',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (groupData['profile_picture'] != null &&
                (groupData['profile_picture'] as String).isNotEmpty)
              CachedNetworkImage(
                imageUrl: groupData['profile_picture'],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF4F46E5),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF4F46E5),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primary],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.group,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Map<String, dynamic> groupData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(0, 80, 255, 0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            groupData['description'] ?? 'No description provided.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, List<String> members) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: Color.fromARGB(255, 255, 255, 255),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Members (${members.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...members.asMap().entries.map((entry) {
            final index = entry.key;
            final memberId = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: index == members.length - 1 ? 0 : 12),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(memberId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final photoURL = userData?['photoURL'] as String?;
                  final displayName = userData?['displayName'] ?? userData?['email'] ?? 'Unknown User';
                  final email = userData?['email'] ?? '';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppColors.primary,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: (photoURL != null && photoURL.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: photoURL,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  )
                                : const Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (memberId == FirebaseAuth.instance.currentUser?.uid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showExitGroupDialog(context),
            icon: const Icon(Icons.exit_to_app, size: 20),
            label: const Text(
              'Leave Group',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _showExitGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Leave Group',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            'Are you sure you want to leave this group? You won\'t be able to see new messages unless someone adds you back.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitGroup(context, groupId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Leave',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exitGroup(BuildContext context, String groupId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
          'members': FieldValue.arrayRemove([user.uid]),
        });
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have left the group'),
              backgroundColor: Color(0xFF000000),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave group: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}