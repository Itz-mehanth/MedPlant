import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicinal_plant/home_page.dart';
import 'dart:io';

import 'group_details_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _searchQuery = "";
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Groups',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, colorScheme),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildSearchSection(colorScheme),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _buildGroupsList(colorScheme),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(colorScheme),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 20,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    );
  }

  Widget _buildSearchSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: "Search your groups...",
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSearchFocused ? Icons.search_rounded : Icons.search_rounded,
              color: _isSearchFocused 
                ? AppColors.primary 
                : colorScheme.onSurfaceVariant,
              key: ValueKey(_isSearchFocused),
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildGroupsList(ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(colorScheme);
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(colorScheme);
          }

          var joinedGroups = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var name = data['name'] as String? ?? '';
            return name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (joinedGroups.isEmpty) {
            return _buildNoResultsState(colorScheme);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: joinedGroups.length,
            itemBuilder: (context, index) {
              var groupDoc = joinedGroups[index];
              var group = groupDoc.data() as Map<String, dynamic>;
              return AnimatedContainer(
                duration: Duration(milliseconds: 100 + (index * 50)),
                child: _buildGroupCard(group, groupDoc.id, colorScheme, index),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your groups...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first group or discover\nexisting ones to get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateGroupDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchGroupsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Find Groups'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, String groupId, 
                        ColorScheme colorScheme, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatPage(
                  groupId: groupId,
                  groupName: group['name'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Hero(
                  tag: 'group_avatar_$groupId',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primary,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: (group['profile_picture'] != null && 
                             group['profile_picture'].isNotEmpty)
                          ? Image.network(
                              group['profile_picture'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.groups_rounded,
                                  size: 28,
                                  color: Colors.white,
                                );
                              },
                            )
                          : Icon(
                              Icons.groups_rounded,
                              size: 28,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'] ?? 'Unnamed Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group['description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(group['members'] as List?)?.length ?? 0} members',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: "search_groups",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchGroupsPage(),
              ),
            );
          },
          icon: const Icon(Icons.search_rounded),
          label: const Text('Find Groups'),
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: "create_group",
          onPressed: () => _showCreateGroupDialog(context),
          backgroundColor: AppColors.primary,
          foregroundColor: colorScheme.onPrimary,
          child: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    File? profilePicture;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Text(
                          'Create New Group',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedFile != null) {
                                  setDialogState(() {
                                    profilePicture = File(pickedFile.path);
                                  });
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: profilePicture != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(
                                          profilePicture!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_rounded,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Group Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: "Enter group name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "What's this group about?",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading || nameController.text.isEmpty
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isLoading = true;
                                    });
                                    
                                    await _createGroup(
                                      nameController.text,
                                      descriptionController.text,
                                      profilePicture,
                                    );
                                    
                                    Navigator.pop(context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Create Group'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createGroup(String name, String description, File? imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String groupId = FirebaseFirestore.instance.collection('groups').doc().id;
      String profilePictureUrl = "";

      if (imageFile != null) {
        String filePath = 'groups/$groupId/profile_picture.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
        await storageRef.putFile(imageFile);
        profilePictureUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('groups').doc(groupId).set({
        'name': name,
        'description': description,
        'created_by': user.uid,
        'members': [user.uid],
        'profile_picture': profilePictureUrl,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error appropriately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class SearchGroupsPage extends StatefulWidget {
  const SearchGroupsPage({super.key});

  @override
  _SearchGroupsPageState createState() => _SearchGroupsPageState();
}

class _SearchGroupsPageState extends State<SearchGroupsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _searchedGroups = [];
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  bool _isLoading = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchGroups(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchedGroups = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(50)
          .get();

      setState(() {
        _searchedGroups = snapshot.docs.map((doc) {
          Map<String, dynamic> groupData = doc.data() as Map<String, dynamic>;
          groupData['id'] = doc.id;
          return groupData;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Discover Groups',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FadeTransition(
              opacity: _animationController,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: "Search for groups to join...",
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: _isLoading
                        ? Container(
                            padding: const EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                          ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchedGroups = [];
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  onChanged: (value) {
                    // Debounce search to avoid too many requests
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _searchGroups(value);
                      }
                    });
                  },
                  onSubmitted: _searchGroups,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildSearchResults(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    if (_searchController.text.isEmpty) {
      return _buildSearchSuggestions(colorScheme);
    }

    if (_isLoading) {
      return _buildLoadingState(colorScheme);
    }

    if (_searchedGroups.isEmpty) {
      return _buildNoResultsFound(colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _searchedGroups.length,
      itemBuilder: (context, index) {
        final group = _searchedGroups[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 100 + (index * 50)),
          child: _buildSearchGroupCard(group, colorScheme, index),
        );
      },
    );
  }

  Widget _buildSearchSuggestions(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.explore_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Discover Amazing Groups',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for groups by name to find\ncommunities that match your interests',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Try searching for topics you love!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching for groups...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or create your own group',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger create group dialog on previous page
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchGroupCard(Map<String, dynamic> group, 
                              ColorScheme colorScheme, int index) {
    final bool isMember = (group['members'] as List?)?.contains(currentUser?.uid) ?? false;
    final int memberCount = (group['members'] as List?)?.length ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatPage(
                  groupId: group['id'],
                  groupName: group['name'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.primary,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: (group['profile_picture'] != null && 
                               group['profile_picture'].isNotEmpty)
                            ? Image.network(
                                group['profile_picture'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.groups_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  );
                                },
                              )
                            : Icon(
                                Icons.groups_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['name'] ?? 'Unnamed Group',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$memberCount members',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isMember) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Joined',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (group['description'] != null && 
                    group['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    group['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: isMember
                          ? OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupChatPage(
                                      groupId: group['id'],
                                      groupName: group['name'],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text('Open Chat'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _joinGroup(group['id']),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Join Group'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Show group details or more options
                          _showGroupDetails(group, colorScheme);
                        },
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupDetails(Map<String, dynamic> group, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.primary,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: (group['profile_picture'] != null && 
                             group['profile_picture'].isNotEmpty)
                          ? Image.network(
                              group['profile_picture'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.groups_rounded,
                                  size: 32,
                                  color: Colors.white,
                                );
                              },
                            )
                          : Icon(
                              Icons.groups_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'] ?? 'Unnamed Group',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(group['members'] as List?)?.length ?? 0} members',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (group['description'] != null && 
                  group['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinGroup(String groupId) async {
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
          'members': FieldValue.arrayUnion([currentUser!.uid]),
        });
        
        // Refresh search to update UI
        _searchGroups(_searchController.text);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Successfully joined the group!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to join group: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }
}