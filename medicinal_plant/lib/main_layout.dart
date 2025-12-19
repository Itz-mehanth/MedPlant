import 'package:flutter/material.dart';
import 'package:medicinal_plant/MarketPlaceProfilePage.dart';
import 'package:medicinal_plant/SocialFeedPage.dart';
import 'package:medicinal_plant/cart_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:medicinal_plant/marketplace_page.dart';

import 'package:medicinal_plant/home_page.dart';  // Added for WelcomeScreen

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    // 0. Home: Plants Search & Chatbot (WelcomeScreen)
    const WelcomeScreen(),
    
    // 1. Feed: Social Feed
    SocialFeedPage(),
    
    // 2. Add: (Placeholder)
    Container(), 
    
    // 3. Marketplace
    const MarketplacePage(),
    
    // 4. Cart
    const CartPage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddOptions();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Create', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(
                  icon: Icons.post_add, 
                  label: 'Post', 
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage()));
                  }
                ),
                _buildOption(
                  icon: Icons.store, 
                  label: 'Product', 
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    // Open Profile and trigger add product? 
                    // Or open a standalone Add Product screen?
                    // Because 'Add Product' dialog is inside MarketplaceProfilePage, we might need to navigate there.
                    // Ideally, we move `_addProduct` to a standalone widget or static method.
                    // For now, let's navigate to Profile and show a snackbar saying "Use the button in profile" 
                    // or switch tab to profile.
                    setState(() => _currentIndex = 4);
                    // Check if we can trigger the dialog. A bit hard without state management or GlobalKey.
                    // Let's just switch to Profile for now.
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add products from your Store tab')));
                  }
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.spa_outlined), activeIcon: Icon(Icons.spa), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.dynamic_feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 40), activeIcon: Icon(Icons.add_circle, size: 40), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart'),
        ],
      ),
    );
  }
}
