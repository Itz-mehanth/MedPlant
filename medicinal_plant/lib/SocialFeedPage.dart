import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Removed
import 'package:medicinal_plant/utils/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:medicinal_plant/utils/notification_service.dart';
import 'package:share_plus/share_plus.dart';

// Main Social Feed Page
class SocialFeedPage extends StatefulWidget {
  @override
  _SocialFeedPageState createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends State<SocialFeedPage>
    with TickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _pageController = PageController();
    _animationController.forward();
  }

  @override
  void dispose() {

    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPosts(),
              builder: (context, snapshot) {

                if (snapshot.hasError) {
                   return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          SelectableText(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {

                  return _buildEmptyState();
                }
                final posts = snapshot.data!;

                return PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: posts.length,
                  onPageChanged: (index) => setState(() {

                    _currentIndex = index;
                  }),
                  itemBuilder: (context, index) {
                    final postData = posts[index];

                    return PostWidget(
                      post: postData['data'],
                      postId: postData['postId'],
                      userId: postData['userId'],
                      currentUser: currentUser,
                    );
                  },
                );
              },
            ),
            _buildAppBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feed',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () {

                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CreatePostPage()));
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8)
                  ],
                ),
                child: Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.video_library_outlined,
                size: 64, color: Colors.green),
          ),
          SizedBox(height: 24),
          Text(
            'No Posts Yet',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Text(
            'Be the first to share something amazing!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {

              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CreatePostPage()));
            },
            icon: Icon(Icons.add),
            label: Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch posts and include both userId and postId for each post
  Future<List<Map<String, dynamic>>> _getPosts() async {

    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('posts')
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final segments = doc.reference.path.split('/');
      final userIdIndex = segments.indexOf('users') + 1;
      final userId = userIdIndex > 0 && userIdIndex < segments.length
          ? segments[userIdIndex]
          : '';

      return {
        'data': doc.data(),
        'postId': doc.id,
        'userId': userId,
      };
    }).toList();
  }
}

// Individual Post Widget
class PostWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;
  final String userId;
  final User? currentUser;

  PostWidget({
    required this.post,
    required this.postId,
    required this.userId,
    required this.currentUser,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  VideoPlayerController? _videoController;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();

    _initializePost();
    if (widget.post['media_type'] == 'video') {
      _initializeVideo();
    }
  }

  void _initializePost() {

    _likeCount = (widget.post['likes'] as List?)?.length ?? 0;
    _commentCount = (widget.post['comments'] as List?)?.length ?? 0;
    _isLiked =
        (widget.post['likes'] as List?)?.contains(widget.currentUser?.uid) ??
            false;
    _isSaved =
        (widget.post['saved_by'] as List?)?.contains(widget.currentUser?.uid) ??
            false;

  }

  void _initializeVideo() {

    _videoController = VideoPlayerController.network(widget.post['media_url'])
      ..initialize().then((_) {

        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play();
      });
  }

  @override
  void dispose() {

    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        _buildMediaContent(),
        _buildOverlay(),
        _buildUserInfo(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildMediaContent() {

    if (widget.post['media_type'] == 'video') {
      return _videoController?.value.isInitialized == true
          ? VideoPlayer(_videoController!)
          : Container(
              color: Colors.grey[200],
              child: Center(child: CircularProgressIndicator()));
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: CachedNetworkImage(
          imageUrl: widget.post['media_url'],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(child: CircularProgressIndicator())),
          errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.error, color: Colors.grey)),
        ),
      );
    }
  }

  Widget _buildOverlay() {

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          stops: [0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {

    return Positioned(
      bottom: 100,
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade900]),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: widget.post['user_avatar'] != null
                      ? CachedNetworkImage(
                          imageUrl: widget.post['user_avatar'],
                          fit: BoxFit.cover)
                      : Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
              SizedBox(width: 12),
              Text(
                widget.post['username'] ?? 'Anonymous',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (widget.post['caption'] != null &&
              widget.post['caption'].isNotEmpty)
            Text(
              widget.post['caption'],
              style: TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (widget.post['location'] != null &&
              widget.post['location'].isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white70, size: 16),
                SizedBox(width: 4),
                Text(
                  widget.post['location'],
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {

    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _toggleLike,
            count: _likeCount,
          ),
          SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.comment_outlined,
            color: Colors.white,
            onTap: _showComments,
            count: _commentCount,
          ),
          SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.share_outlined,
            color: Colors.white,
            onTap: _sharePost,
          ),
          SizedBox(height: 24),
          _buildActionButton(
            icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: _isSaved ? Colors.yellow : Colors.white,
            onTap: _toggleSave,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap,
      int? count}) {

    return Column(
      children: [
        GestureDetector(
          onTap: () {

            onTap();
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        if (count != null && count > 0) ...[
          SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {

    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _toggleLike() async {

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    // Update Firebase
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('posts')
        .doc(widget.postId);
    if (_isLiked) {

      await docRef.update({
        'likes': FieldValue.arrayUnion([widget.currentUser?.uid])
      });
      });
    }

    if (_isLiked && widget.userId != widget.currentUser?.uid) {
      NotificationService.sendNotification(
        recipientId: widget.userId,
        title: 'New Like',
        body: '${widget.currentUser?.displayName ?? 'Someone'} liked your post',
        type: 'like',
        relatedId: widget.postId,
      );
    }
  }

  void _toggleSave() async {

    setState(() {
      _isSaved = !_isSaved;
    });
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('posts')
        .doc(widget.postId);
    if (_isSaved) {

      await docRef.update({
        'saved_by': FieldValue.arrayUnion([widget.currentUser?.uid])
      });
    } else {

      await docRef.update({
        'saved_by': FieldValue.arrayRemove([widget.currentUser?.uid])
      });
    }
  }

  void _showComments() {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsBottomSheet(postId: widget.postId, userId: widget.userId),
    );
  }

  void _sharePost() async {
    final caption = widget.post['caption'] ?? 'Check out this post!';
    final mediaUrl = widget.post['media_url'] ?? '';
    final username = widget.post['username'] ?? 'MedPlant User';
    
    final shareText = '$caption\n\nPosted by $username\n$mediaUrl\n\nSent via MedPlant App';
    
    try {
      await Share.share(shareText);
       
      // Notify owner if shared by someone else
      if (widget.userId != widget.currentUser?.uid) {
        NotificationService.sendNotification(
          recipientId: widget.userId,
          title: 'Post Shared',
          body: '${widget.currentUser?.displayName ?? 'Someone'} shared your post',
          type: 'share',
          relatedId: widget.postId,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Create Post Page
class CreatePostPage extends StatefulWidget { // Removed _ to make public
  const CreatePostPage({super.key});
  
  @override
  CreatePostPageState createState() => CreatePostPageState();
}

class CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  File? _selectedMedia;
  String _mediaType = '';
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Create Post',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed:
                _selectedMedia != null && !_isUploading ? _uploadPost : null,
            child: _isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Post',
                    style: TextStyle(
                        color: _selectedMedia != null
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedMedia == null
                ? _buildMediaSelector()
                : _buildMediaPreview(),
          ),
          _buildPostDetails(),
        ],
      ),
    );
  }

  Widget _buildMediaSelector() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.add_photo_alternate_outlined,
                size: 64, color: Colors.green),
          ),
          SizedBox(height: 24),
          Text('Select Media',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaButton(Icons.photo_camera, 'Camera',
                  () => _pickMedia(ImageSource.camera)),
              _buildMediaButton(Icons.photo_library, 'Gallery',
                  () => _pickMedia(ImageSource.gallery)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 32),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.green.shade900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      child: _mediaType == 'image'
          ? Image.file(_selectedMedia!, fit: BoxFit.cover)
          : Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, color: Colors.grey, size: 64),
                    Text('Video Selected',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPostDetails() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _captionController,
            style: TextStyle(color: Colors.black),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a caption...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
          Divider(color: Colors.grey[300]),
          TextField(
            controller: _locationController,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Add location',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.location_on, color: Colors.grey),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _pickMedia(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedMedia = File(pickedFile.path);
        _mediaType = 'image';
      });
    }
  }

  Future<void> _uploadPost() async {
    setState(() => _isUploading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload media to Cloudinary
      final mediaUrl = await CloudinaryService.uploadImage(_selectedMedia!.path);
      
      if (mediaUrl == null) {
          throw Exception('Image upload failed');
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // Create post data
      final postData = {
        'media_url': mediaUrl,
        'media_type': _mediaType,
        'caption': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'user_id': user.uid,
        'username': userData['displayName'] ?? userData['email'] ?? 'Anonymous',
        'user_avatar': userData['photoURL'] ?? '',
        'likes': [],
        'comments': [],
        'saved_by': [],
        'created_at': FieldValue.serverTimestamp(),
      };

      // Save to user's posts collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posts')
          .add(postData);

      // System Notification
      NotificationService.sendNotification(
        recipientId: user.uid,
        title: 'Post Uploaded',
        body: 'Your post is now live!',
        type: 'system',
        relatedId: null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Post uploaded successfully!'),
              backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload post: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

}

// Comments Bottom Sheet
class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String userId;

  CommentsBottomSheet({required this.postId, required this.userId});

  @override
  _CommentsBottomSheetState createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text('Comments',
                    style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator(color: Colors.green));

                final postData = snapshot.data!.data() as Map<String, dynamic>?;
                final comments = (postData?['comments'] as List?) ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text('No comments yet', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index] as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: comment['user_avatar'] != null && comment['user_avatar'].isNotEmpty
                                ? CachedNetworkImageProvider(comment['user_avatar'])
                                : null,
                            child: comment['user_avatar'] == null || comment['user_avatar'].isEmpty
                                ? Icon(Icons.person, color: Colors.grey.shade400, size: 20)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['username'] ?? 'Anonymous',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text(comment['text'] ?? '',
                                    style: TextStyle(color: Colors.black87, fontSize: 14)),
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
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.green.shade600, size: 20),
                    onPressed: _addComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    final comment = {
      'user_id': currentUser!.uid,
      'username': userData['displayName'] ?? userData['email'] ?? 'Anonymous',
      'user_avatar': userData['photoURL'] ?? '',
      'text': _commentController.text.trim(),
      'created_at': DateTime.now().toIso8601String(), // Use simpler timestamp for array
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('posts')
        .doc(widget.postId)
        .update({
      'comments': FieldValue.arrayUnion([comment])
    });

    if (widget.userId != currentUser!.uid) {
      NotificationService.sendNotification(
        recipientId: widget.userId,
        title: 'New Comment',
        body: '${userData['displayName'] ?? 'Someone'} commented on your post',
        type: 'comment',
        relatedId: widget.postId,
      );
    }

    _commentController.clear();
  }
}
