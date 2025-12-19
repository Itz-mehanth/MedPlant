import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medicinal_plant/providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicinal_plant/chat_page.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Future<void> _contactSeller(BuildContext context, String sellerId, WidgetRef ref) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to contact seller')),
      );
      return;
    }

    if (sellerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot contact yourself')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Fetch seller details
      final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
      if (!sellerDoc.exists) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seller not found')),
        );
        return;
      }

      final sellerData = sellerDoc.data() as Map<String, dynamic>;
      final sellerName = sellerData['displayName'] ?? 'Seller';
      final sellerAvatar = sellerData['photoURL'] ?? '';

      // 2. Fetch current user details (to update participantDetails)
      // We might already have this cached, but fetching ensures freshness
      final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>? ?? {};
      final currentUserName = currentUserData['displayName'] ?? currentUser.displayName ?? 'User';
      final currentUserAvatar = currentUserData['photoURL'] ?? currentUser.photoURL ?? '';

      // 3. Generate Chat ID (deterministic)
      final List<String> ids = [currentUser.uid, sellerId];
      ids.sort();
      final chatId = ids.join('_');

      // 4. Check/Create Chat Document
      final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      final chatDoc = await chatDocRef.get();

      if (!chatDoc.exists) {
        // Create new chat with participant details
        await chatDocRef.set({
          'participants': ids,
          'participantDetails': {
            currentUser.uid: {
              'name': currentUserName,
              'avatar': currentUserAvatar,
            },
            sellerId: {
              'name': sellerName,
              'avatar': sellerAvatar,
            },
          },
          'startedAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessage': 'Chat started', 
        });
      }

      Navigator.pop(context); // Close loading

      // 5. Navigate to ChatPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: chatId,
            otherUserId: sellerId,
            otherUserName: sellerName,
            otherUserAvatar: sellerAvatar,
          ),
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading
      print('Error contacting seller: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error contacting seller')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    // Subtotal is no longer strictly necessary if there's no checkout, but good for info.
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Shopping Cart', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: Key(item.productId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(cartProvider.notifier).removeFromCart(item.productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item.name} removed')),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[100],
                                      child: item.imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: item.imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (c, u) => Center(child: CircularProgressIndicator(strokeWidth: 2)), 
                                              errorWidget: (c, u, e) => Icon(Icons.local_florist, color: Colors.green),
                                            )
                                          : Icon(Icons.local_florist, color: Colors.green),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '₹${item.price}',
                                          style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove, size: 18),
                                        onPressed: () {
                                           ref.read(cartProvider.notifier).decrementQuantity(item.productId);
                                        },
                                      ),
                                      Text('${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold)),
                                      // Removed add button to simplify - user can go back to store
                                      // Or keep it but functionally it might be limited without full product object
                                      // Keeping consistent with previous view
                                      IconButton(
                                         icon: Icon(Icons.add, size: 18, color: Colors.grey), // Disabled look or just remove
                                         onPressed: null, // Disabled for now as we need full product object to add
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              SizedBox(height: 12),
                              // Contact Seller Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _contactSeller(context, item.sellerId, ref),
                                  icon: Icon(Icons.chat_bubble_outline, size: 18),
                                  label: Text('Contact Seller'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: BorderSide(color: Colors.green),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Removed the bottom Checkout container entirely
                 Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], // Slightly different background
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Estimated Total: ', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        Text('₹${subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
