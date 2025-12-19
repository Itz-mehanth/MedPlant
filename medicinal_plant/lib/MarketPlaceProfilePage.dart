import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicinal_plant/utils/cloudinary_service.dart';
import 'package:medicinal_plant/auth.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart'; // Removed
import 'package:url_launcher/url_launcher.dart';
import 'package:medicinal_plant/providers/cart_provider.dart';
import 'package:medicinal_plant/chat_page.dart';
import 'package:medicinal_plant/utils/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:medicinal_plant/chat_page.dart';
import 'package:medicinal_plant/utils/notification_service.dart';
import 'package:medicinal_plant/SavedPostsPage.dart';
import 'package:intl/intl.dart';

class MarketplaceProfilePage extends ConsumerStatefulWidget {
  final String? userId;
  
  const MarketplaceProfilePage({super.key, this.userId});

  @override
  _MarketplaceProfilePageState createState() => _MarketplaceProfilePageState();
}

class _MarketplaceProfilePageState extends ConsumerState<MarketplaceProfilePage>
    with TickerProviderStateMixin {
  User? currentUser;
  String? profileUserId;
  bool isOwnProfile = true;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? profileData;
  List<DocumentSnapshot> userPosts = [];
  List<DocumentSnapshot> storeProducts = [];
  bool isLoading = true;
  bool isSellerMode = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    profileUserId = widget.userId ?? currentUser?.uid;
    isOwnProfile = profileUserId == currentUser?.uid;
    
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadProfileData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (profileUserId == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(profileUserId!)
          .get();
      
      if (userDoc.exists) {
        profileData = userDoc.data();
        isSellerMode = profileData?['seller_mode'] ?? false;
      }

      final postsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(profileUserId!)
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();
      
      userPosts = postsSnapshot.docs;

      if (isSellerMode) {
        final productsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(profileUserId!)
            .collection('products')
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true)
            .limit(50)
            .get();
        
        storeProducts = productsSnapshot.docs;
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              elevation: 0,
              actions: [
                if (isOwnProfile)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'saved_posts',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SavedPostsPage())),
                        child: const Row(
                          children: [
                            Icon(Icons.bookmark_border, size: 20),
                            SizedBox(width: 12),
                            Text('Saved Posts'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'messages',
                        onTap: () => Navigator.pushNamed(context, '/messages'),
                        child: const Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 20),
                            SizedBox(width: 12),
                            Text('My Messages'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_profile',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_feedback',
                        child: Row(
                          children: [
                            Icon(Icons.feedback, size: 20),
                            SizedBox(width: 12),
                            Text('Add Feedback'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'groups',
                        onTap: () => Navigator.pushNamed(context, '/groups'),
                        child: const Row(
                          children: [
                            Icon(Icons.group, size: 20),
                            SizedBox(width: 12),
                            Text('Groups'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'gallery',
                        onTap: () => Navigator.pushNamed(context, '/gallery'),
                        child: const Row(
                          children: [
                            Icon(Icons.browse_gallery, size: 20),
                            SizedBox(width: 12),
                            Text('Gallery'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'seller_mode',
                        child: Row(
                          children: [
                            Icon(isSellerMode ? Icons.store_outlined : Icons.store, size: 20),
                            SizedBox(width: 12),
                            Text(isSellerMode ? 'Disable Store' : 'Enable Store'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, size: 20),
                            SizedBox(width: 12),
                            Text('Settings'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProfileHeader(colorScheme),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildTabBar(colorScheme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsGrid(),
                  if (isSellerMode) _buildStoreGrid() else _buildEmptyStore(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isOwnProfile ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    final displayName = profileData?['displayName'] ?? profileData?['email'] ?? 'User';
    final bio = profileData?['bio'] ?? '';
    final location = profileData?['location'] ?? '';
    final photoURL = profileData?['photoURL'] ?? '';
    final isVerified = profileData?['verified'] ?? false;
    final rating = profileData?['rating']?.toDouble() ?? 0.0;
    final totalOrders = profileData?['total_orders'] ?? 0;

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 60),
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade900],
                  ),
                ),
                child: GestureDetector(
                  onTap: isOwnProfile ? _uploadProfilePic : null,
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: photoURL.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoURL,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(Icons.person, color: Colors.white, size: 45),
                        )
                      : Icon(Icons.person, color: Colors.white, size: 45),
                ),
                ),
              ),

              SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Posts', userPosts.length.toString()),
                    if (isSellerMode) ...[
                      _buildStatColumn('Products', storeProducts.length.toString()),
                      _buildStatColumn('Orders', totalOrders.toString()),
                    ] else ...[
                      _buildStatColumn('Following', '0'),
                      _buildStatColumn('Followers', '0'),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (isVerified) ...[
                SizedBox(width: 8),
                Icon(Icons.verified, color: Colors.green, size: 20),
              ],
            ],
          ),
          if (isSellerMode && rating > 0) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
          if (bio.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (location.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: colorScheme.onSurfaceVariant, size: 16),
                SizedBox(width: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (!isOwnProfile) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _handleFollowUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Follow', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleMessageUser,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(Icons.message_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: Colors.green,
        indicatorWeight: 2,
        tabs: [
          Tab(icon: Icon(Icons.grid_on_outlined), text: 'Posts'),
          Tab(icon: Icon(isSellerMode ? Icons.store_outlined : Icons.store_mall_directory_outlined), text: 'Store'),
          Tab(icon: Icon(Icons.info_outline), text: 'About'),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    if (userPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.camera_alt_outlined,
        title: isOwnProfile ? 'No posts yet' : 'No posts',
        subtitle: isOwnProfile ? 'Share your first moment!' : 'This user hasn\'t posted anything yet',
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index].data() as Map<String, dynamic>;
        final mediaUrl = post['media_url'] ?? '';
        final mediaType = post['media_type'] ?? 'image';
        
        return GestureDetector(
          onTap: () => _openPostDetail(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (mediaUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: mediaUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.error, color: Colors.white54),
                    ),
                  ),
                if (mediaType == 'video')
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreGrid() {
    if (storeProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        title: isOwnProfile ? 'No products yet' : 'No products available',
        subtitle: isOwnProfile ? 'Add your first herbal product!' : 'This seller hasn\'t added any products yet',
        actionButton: isOwnProfile ? ElevatedButton.icon(
          onPressed: _addProduct,
          icon: Icon(Icons.add),
          label: Text('Add Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ) : null,
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: storeProducts.length,
      itemBuilder: (context, index) {
        final product = storeProducts[index].data() as Map<String, dynamic>;
        return _buildProductCard(product, storeProducts[index].id);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String productId) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = product['name'] ?? 'Unnamed Product';
    final price = product['price']?.toString() ?? '0';
    final currency = product['currency'] ?? '₹';
    final imageUrl = (product['images'] as List?)?.first ?? '';
    final inStock = product['stock_quantity'] ?? 0;
    
    return GestureDetector(
      onTap: () => _openProductDetail(productId, product),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => Icon(Icons.local_florist, size: 40, color: Colors.green),
                        )
                      : Icon(Icons.local_florist, size: 40, color: Colors.green),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currency$price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        if (inStock <= 5 && inStock > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Low Stock',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else if (inStock == 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildEmptyStore() {
    return _buildEmptyState(
      icon: Icons.store_outlined,
      title: isOwnProfile ? 'Store not enabled' : 'No store available',
      subtitle: isOwnProfile ? 'Enable seller mode to start selling herbal products' : 'This user is not a seller',
      actionButton: isOwnProfile ? ElevatedButton.icon(
        onPressed: () => _toggleSellerMode(true),
        icon: Icon(Icons.store),
        label: Text('Enable Store'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ) : null,
    );
  }

  Widget _buildAboutTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final joinedDate = profileData?['created_at'] != null 
        ? (profileData!['created_at'] as Timestamp).toDate()
        : DateTime.now();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection(
            'Contact Information',
            [
              if (profileData?['email'] != null)
                _buildInfoRow(Icons.email_outlined, 'Email', profileData!['email']),
              if (profileData?['phone'] != null)
                _buildInfoRow(Icons.phone_outlined, 'Phone', profileData!['phone']),
              if (profileData?['website'] != null)
                _buildInfoRow(Icons.language_outlined, 'Website', profileData!['website']),
            ],
          ),
          SizedBox(height: 24),
          _buildAboutSection(
            'Account Details',
            [
              _buildInfoRow(Icons.calendar_today_outlined, 'Joined', 
                  '${joinedDate.day}/${joinedDate.month}/${joinedDate.year}'),
              if (isSellerMode) ...[
                _buildInfoRow(Icons.verified_user_outlined, 'Seller Status', 
                    profileData?['verified'] == true ? 'Verified' : 'Unverified'),
                _buildInfoRow(Icons.local_shipping_outlined, 'Shipping', 
                    profileData?['ships_nationwide'] == true ? 'Nationwide' : 'Local only'),
              ],
            ],
          ),
          if (isSellerMode) ...[
            SizedBox(height: 24),
            _buildAboutSection(
              'Store Policies',
              [
                _buildPolicyItem('Return Policy', profileData?['return_policy'] ?? 'Contact seller'),
                _buildPolicyItem('Shipping Time', '${profileData?['shipping_days'] ?? 3-7} days'),
                _buildPolicyItem('Minimum Order', '${profileData?['currency'] ?? '₹'}${profileData?['minimum_order'] ?? 0}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String title, String description) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? actionButton,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isSellerMode)
          FloatingActionButton(
            heroTag: 'add_product',
            onPressed: _addProduct,
            backgroundColor: Color(0xFF10B981),
            child: Icon(Icons.add_business, color: Colors.white),
          ),
        SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'add_post',
          onPressed: _addPost,
          backgroundColor: Colors.green,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_profile':
        _editProfile();
        break;
      case 'seller_mode':
        _toggleSellerMode(!isSellerMode);
        break;
      case 'settings':
        _openSettings();
        break;
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: profileData?['displayName'] ?? '');
    final bioController = TextEditingController(text: profileData?['bio'] ?? '');
    final phoneController = TextEditingController(text: profileData?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Display Name'),
              ),
              TextField(
                controller: bioController,
                decoration: InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone (Optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .update({
                  'displayName': nameController.text,
                  'bio': bioController.text,
                  'phone': phoneController.text,
                });
                Navigator.pop(context);
                _loadProfileData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating profile: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSellerMode(bool enable) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profileUserId!)
          .update({'seller_mode': enable});
      
      setState(() => isSellerMode = enable);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable ? 'Store enabled successfully!' : 'Store disabled'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      
      _loadProfileData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openSettings() {}

  void _addPost() {
    Navigator.pushNamed(context, '/create_post');
  }

  void _addProduct() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final stockController = TextEditingController();
    bool _isUploading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: stockController,
                  decoration: InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                if (_isUploading)
                  CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      setDialogState(() => _isUploading = true);
                      
                      try {
                        // 1. Pick Image (Optional)
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        String? imageUrl;

                        if (image != null) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploading image...')));
                           imageUrl = await CloudinaryService.uploadImage(image.path);
                           if (imageUrl == null) {
                             throw Exception("Image upload failed");
                           }
                        }

                        // 2. Prepare Data
                        final productData = {
                          'name': nameController.text,
                          'price': double.tryParse(priceController.text) ?? 0.0,
                          'description': descriptionController.text,
                          'stock_quantity': int.tryParse(stockController.text) ?? 0,
                          'images': imageUrl != null ? [imageUrl] : [],
                          'is_active': true,
                          'created_at': FieldValue.serverTimestamp(),
                          'currency': '₹',
                        };

                        // 3. Save to Firestore
                        final docRef = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser!.uid)
                            .collection('products')
                            .add(productData);
                        
                        // 4. Send Notification
                        NotificationService.sendNotification(
                          recipientId: currentUser!.uid,
                          title: 'Product Uploaded',
                          body: 'Your product "${nameController.text}" is live!',
                          type: 'system',
                          relatedId: docRef.id, 
                        );

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          _loadProfileData(); 
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product Added!')));
                        }
                      } catch (e) {
                         print('Error adding product: $e');
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        if (mounted) {
                           setDialogState(() => _isUploading = false);
                        }
                      }
                    },
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('Save Product'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
              ],
            ),
          ),
          actions: [
             TextButton(
               onPressed: () => Navigator.pop(dialogContext),
               child: Text("Cancel"),
             )
          ],
        ),
      ),
    );
  }

  void _handleFollowUser() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('following')
          .doc(profileUserId);

      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unfollowed!')),
        );
      } else {
        await docRef.set({
          'timestamp': FieldValue.serverTimestamp(),
        });
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Followed!')),
        );
      }
    } catch (e) {
      print('Error following: $e');
    }
  }

  void _handleMessageUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Messaging functionality coming soon!')),
    );
  }

  void _openPostDetail(int index) {
    Navigator.pushNamed(context, '/social_feed');
  }

  void _openProductDetail(String productId, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(
        productId: productId,
        product: product,
        sellerId: profileUserId!,
      ),
    );
  }

  Future<void> _uploadProfilePic() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading...')));
        final url = await CloudinaryService.uploadImage(image.path);
        
        if (url != null) {
          await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'photoURL': url});
          await currentUser!.updatePhotoURL(url);
          await currentUser!.reload();
          currentUser = FirebaseAuth.instance.currentUser;
          
          setState(() {
             profileData?['photoURL'] = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!')));
        }
      } catch (e) {
        print('Error: $e');
      }
    }
  }
}

class ProductDetailSheet extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> product;
  final String sellerId;

  const ProductDetailSheet({
    required this.productId,
    required this.product,
    required this.sellerId,
  });

  Widget _buildReviewsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();
        final reviews = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reviews (${reviews.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddReviewDialog(sellerId: sellerId, productId: productId),
                      );
                    },
                    icon: Icon(Icons.rate_review),
                    label: Text('Write Review'),
                  ),
                ],
              ),
            ),
            if (reviews.isEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Text('No reviews yet. Be the first!', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(review['user_avatar'] ?? ''),
                      child: review['user_avatar'] == null ? Icon(Icons.person) : null,
                    ),
                    title: Text(review['user_name'] ?? 'Anonymous'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: List.generate(5, (i) => Icon(i < (review['rating'] ?? 0) ? Icons.star : Icons.star_border, size: 14, color: Colors.amber))),
                        Text(review['comment'] ?? ''),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = product['name'] ?? 'Unnamed Product';
    final description = product['description'] ?? '';
    final price = product['price']?.toString() ?? '0';
    final currency = product['currency'] ?? '₹';
    final images = (product['images'] as List?)?.cast<String>() ?? [];
    final category = product['category'] ?? '';
    final inStock = product['stock_quantity'] ?? 0;
    final benefits = (product['benefits'] as List?)?.cast<String>() ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                  if (sellerId == FirebaseAuth.instance.currentUser?.uid)
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        // Show edit dialog
                        final nameController = TextEditingController(text: name);
                        final priceController = TextEditingController(text: price);
                        final descriptionController = TextEditingController(text: description);
                        final stockController = TextEditingController(text: inStock.toString());
                        
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Edit Product'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(labelText: 'Product Name'),
                                  ),
                                  TextField(
                                    controller: priceController,
                                    decoration: InputDecoration(labelText: 'Price'),
                                    keyboardType: TextInputType.number,
                                  ),
                                  TextField(
                                    controller: descriptionController,
                                    decoration: InputDecoration(labelText: 'Description'),
                                    maxLines: 3,
                                  ),
                                  TextField(
                                    controller: stockController,
                                    decoration: InputDecoration(labelText: 'Stock Quantity'),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(sellerId)
                                        .collection('products')
                                        .doc(productId)
                                        .update({
                                      'name': nameController.text,
                                      'price': double.tryParse(priceController.text) ?? 0.0,
                                      'description': descriptionController.text,
                                      'stock_quantity': int.tryParse(stockController.text) ?? 0,
                                    });
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Close sheet to refresh or show updated info
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product updated!')));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e')));
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (sellerId == FirebaseAuth.instance.currentUser?.uid)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                         final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Product?'),
                              content: Text('This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  child: Text('Delete', style: TextStyle(color: Colors.red))
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(sellerId)
                                .collection('products')
                                .doc(productId)
                                .delete();
                            Navigator.pop(context); // Close sheet
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product deleted!')));
                          }
                      },
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    Container(
                      height: 250,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$currency$price',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: inStock > 0 ? Color(0xFF10B981).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          inStock > 0 ? 'In Stock ($inStock)' : 'Out of Stock',
                          style: TextStyle(
                            color: inStock > 0 ? Color(0xFF10B981) : Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (category.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(76, 175, 80, 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                  if (description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  if (benefits.isNotEmpty) ...[
                    Text(
                      'Health Benefits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    ...benefits.map((benefit) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: EdgeInsets.only(top: 6, right: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              benefit,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 20),
                  _buildReviewsSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contact seller functionality coming soon!')),
                      );
                    },
                    icon: Icon(Icons.chat_outlined, size: 20),
                    label: Text('Contact Seller'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton.icon(
                        onPressed: inStock > 0 ? () {
                          ref.read(cartProvider.notifier).addToCart(product, productId, sellerId);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to cart!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        } : null,
                        icon: Icon(Icons.shopping_cart_outlined, size: 20),
                        label: Text(inStock > 0 ? 'Add to Cart' : 'Out of Stock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class AddReviewDialog extends StatefulWidget {
  final String sellerId;
  final String productId;

  const AddReviewDialog({required this.sellerId, required this.productId});

  @override
  _AddReviewDialogState createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  double _rating = 5;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Write a Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1.0),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(hintText: 'Share your experience...'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) return;

            final reviewData = {
              'user_id': currentUser.uid,
              'user_name': currentUser.displayName ?? 'Anonymous',
              'user_avatar': currentUser.photoURL ?? '',
              'rating': _rating,
              'comment': _commentController.text,
              'timestamp': FieldValue.serverTimestamp(),
            };

            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.sellerId)
                .collection('products')
                .doc(widget.productId)
                .collection('reviews')
                .add(reviewData);

            if (widget.sellerId != currentUser.uid) {
              NotificationService.sendNotification(
                recipientId: widget.sellerId,
                title: 'New Product Review',
                body: '${currentUser.displayName ?? 'Someone'} reviewed your product.',
                type: 'review',
                relatedId: widget.productId,
              );
            }
            Navigator.pop(context);
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
