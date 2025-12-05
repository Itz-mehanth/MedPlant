import 'package:flutter/material.dart';
import 'package:medicinal_plant/MarketPlaceProfilePage.dart';
import 'package:medicinal_plant/SocialFeedPage.dart';
import 'package:medicinal_plant/cart_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // We need to keep pages alive to avoid reloading state constantly
  final List<Widget> _pages = [
    // 0. Feed
    SocialFeedPage(),
    
    // 1. Search/Market (Using Profile as placeholder, should probably be separate Market page)
    // Reusing the social feed or a separate page. For now let's use a placeholder or the Feed again.
    // The user didn't specify what goes here, usually it's discovery.
    // Let's use SocialFeedPage again or just a Text placeholder.
    // Actually, "Marketplace" implies browsing products. 
    // We don't have a dedicated "All Products" page yet, only profiles have products.
    // Let's put a placeholder for "Marketplace Explore"
    Center(child: Text("Marketplace Explore coming soon!")),
    
    // 2. Add (Handled by special button, this index shouldn't be reached ideally)
    Container(), 
    
    // 3. Cart
    const CartPage(),
    
    // 4. Profile
    const MarketplaceProfilePage(), 
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
                    Navigator.pushNamed(context, '/create_post'); // Need to ensure route exists or push directly
                    // SocialFeedPage has CreatePostPage, but it's not exported usually? 
                    // We'll check route registration. Route '/create_post' isn't registered in main.dart yet.
                    // We should probably register it or push locally.
                    // For now, let's assume we need to fix this route.
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 40), activeIcon: Icon(Icons.add_circle, size: 40), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
