import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medicinal_plant/MarketPlaceProfilePage.dart'; // Reuse ProductDetailSheet

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text('Marketplace', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: Icon(Icons.search, color: Colors.grey[800]), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list, color: Colors.grey[800]), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             print("Marketplace Stream Error: ${snapshot.error}");
             return Center(child: Text("Something went wrong. check indexes?"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var products = snapshot.data?.docs ?? [];
          
          // Client-side filtering and sorting to avoid composite index requirement
          // Filter: is_active == true
          // Sort: created_at descending
          final filteredProducts = products.where((doc) {
             final data = doc.data() as Map<String, dynamic>;
             return data['is_active'] == true;
          }).toList();

          filteredProducts.sort((a, b) {
             final dataA = a.data() as Map<String, dynamic>;
             final dataB = b.data() as Map<String, dynamic>;
             final Timestamp? tA = dataA['created_at'];
             final Timestamp? tB = dataB['created_at'];
             if (tA == null || tB == null) return 0;
             return tB.compareTo(tA);
          });
          
          if (filteredProducts.isEmpty) {
            return Center(child: Text("No products found"));
          }

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final doc = filteredProducts[index];
              final data = doc.data() as Map<String, dynamic>;
              // We need sellerId. Since it's collectionGroup, the parent of the parent is the user doc.
              // path: users/{userId}/products/{productId}
              final userPath = doc.reference.parent.parent?.path; 
              final sellerId = userPath?.split('/').last ?? '';

              return GestureDetector(
                onTap: () {
                   showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ProductDetailSheet(
                      product: data, 
                      productId: doc.id,
                      sellerId: sellerId,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: (data['images'] as List?)?.isNotEmpty == true
                                ? CachedNetworkImage(
                                    imageUrl: (data['images'] as List).first,
                                    fit: BoxFit.cover,
                                    placeholder: (c, u) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.green),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? 'Product',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₹${data['price'] ?? 0}',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
