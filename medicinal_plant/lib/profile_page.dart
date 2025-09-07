import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicinal_plant/gallery_page.dart';
import 'package:medicinal_plant/auth.dart';
import 'package:medicinal_plant/google_signin_web.dart';
import 'package:medicinal_plant/home_page.dart';
import 'package:medicinal_plant/login_register_page.dart';
import 'package:medicinal_plant/splash_screen.dart';
import 'package:medicinal_plant/utils/global_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  User? user;
  String? profileURL = FirebaseAuth.instance.currentUser?.photoURL;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    user = Auth().currentUser;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();

    // Listen to auth state changes
    Auth().authStateChanges.listen((User? newUser) {
      if (mounted) {
        setState(() {
          user = newUser;
          profileURL = newUser?.photoURL;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Auth auth = Auth();
  int _selectedOption = 0;
  
  List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'Tamil', 'code': 'ta', 'flag': '🇮🇳'},
    {'name': 'Telugu', 'code': 'te', 'flag': '🇮🇳'},
    {'name': 'Kannada', 'code': 'kn', 'flag': '🇮🇳'},
    {'name': 'Malayalam', 'code': 'ml', 'flag': '🇮🇳'},
    {'name': 'Hindi', 'code': 'hi', 'flag': '🇮🇳'},
    {'name': 'Gujarati', 'code': 'gu', 'flag': '🇮🇳'},
    {'name': 'Oriya', 'code': 'or', 'flag': '🇮🇳'},
    {'name': 'Spanish', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'French', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'German', 'code': 'de', 'flag': '🇩🇪'},
    {'name': 'Italian', 'code': 'it', 'flag': '🇮🇹'},
    {'name': 'Portuguese', 'code': 'pt', 'flag': '🇵🇹'},
    {'name': 'Chinese (Simplified)', 'code': 'zh_CN', 'flag': '🇨🇳'},
    {'name': 'Chinese (Traditional)', 'code': 'zh_TW', 'flag': '🇹🇼'},
    {'name': 'Japanese', 'code': 'ja', 'flag': '🇯🇵'},
    {'name': 'Korean', 'code': 'ko', 'flag': '🇰🇷'},
    {'name': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'Russian', 'code': 'ru', 'flag': '🇷🇺'},
    {'name': 'Bengali', 'code': 'bn', 'flag': '🇧🇩'},
  ];

  Future<void> _updateUserLanguage(String language) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'language': language,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Language updated successfully!'),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating language: $e'),
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

  void _showLanguageDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
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
                        Icon(
                          Icons.language_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Choose Language',
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
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        final isSelected = language['code'] == currentLocale;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? AppColors.primary
                              : colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await _updateUserLanguage(language['code']!);
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      language['flag']!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        language['name']!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected 
                                            ? FontWeight.w600 
                                            : FontWeight.w400,
                                          color: isSelected 
                                            ? AppColors.primary 
                                            : colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Select your preferred language for the app',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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

  void _sendFeedback() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'mehanth362@gmail.com',
      query: 'subject=App Feedback&body=Hi there,\n\nI would like to share my feedback about the app:\n\n',
    );
    
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch email';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open email app'),
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

  void _handleSignOut() async {
    final authService = AuthService();
    
    try {
      if (user?.email != null) {
        await auth.signOut();
      } else if (authService.isLoggedIn) {
        await authService.signOut();
      }
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colorScheme),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildProfileHeader(colorScheme),
                      const SizedBox(height: 32),
                      _buildMenuSection(colorScheme),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color.fromARGB(255, 64, 78, 65),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: profileURL != null
                    ? Image.network(
                        profileURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: AppColors.primary,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: AppColors.primary,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user?.displayName ?? user?.email ?? "Guest User",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user!.email!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (user == null) ...[
            const SizedBox(height: 8),
            Text(
              'Sign in to access all features',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          colorScheme,
          [
            _buildMenuItem(
              icon: user?.email != null ? Icons.logout_rounded : Icons.login_rounded,
              title: user?.email != null ? 'Sign Out' : 'Sign In',
              subtitle: user?.email != null 
                ? 'Sign out of your account'
                : 'Sign in to access all features',
              onTap: user?.email != null ? _handleSignOut : () {
                Navigator.pushNamed(context, '/login');
              },
              iconColor: user?.email != null 
                ? colorScheme.error 
                : AppColors.primary,
              titleColor: user?.email != null 
                ? colorScheme.error 
                : null,
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.language_rounded,
              title: 'Languages',
              subtitle: 'Choose your preferred language',
              onTap: user != null 
                ? _showLanguageDialog 
                : () => showLoginPrompt(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          colorScheme,
          [
            _buildMenuItem(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Browse your photo collection',
              onTap: () {
                Navigator.pushNamed(context, '/gallery');
              },
            ),
            const Divider(height: 1),
            _buildMenuItem(
              icon: Icons.groups_rounded,
              title: 'Groups',
              subtitle: 'Connect with communities',
              onTap: () {
                Navigator.pushNamed(context, '/groups');
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          colorScheme,
          [
            _buildMenuItem(
              icon: Icons.feedback_rounded,
              title: 'Send Feedback',
              subtitle: 'Help us improve the app',
              onTap: _sendFeedback,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(ColorScheme colorScheme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
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
    );
  }
}