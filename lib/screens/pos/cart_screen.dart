// lib/screens/pos/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:pos_app/database/database_helper.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/screens/pos/payment_screen.dart';

class CartScreen extends StatefulWidget {
  final Map<int, int> cart; // productId -> quantity

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> _cartDetailsFuture;
  int _subtotal = 0;
  int _discount = 0;
  int _grandTotal = 0;

  @override
  void initState() {
    super.initState();
    _cartDetailsFuture = _getCartDetails();
  }

  Future<List<Map<String, dynamic>>> _getCartDetails() async {
    List<Map<String, dynamic>> details = [];
    int currentSubtotal = 0;
    for (var entry in widget.cart.entries) {
      Product product = await DatabaseHelper.instance.getProductById(entry.key);
      details.add({'product': product, 'quantity': entry.value});
      currentSubtotal += product.price * entry.value;
    }

    // Fitur 1: Tambahkan diskon otomatis 10%
    final discountValue = (currentSubtotal * 0.1).round();
    final grandTotalValue = currentSubtotal - discountValue;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _subtotal = currentSubtotal;
          _discount = discountValue;
          _grandTotal = grandTotalValue;
        });
      }
    });
    return details;
  }

  void _goToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentScreen(cart: widget.cart, totalAmount: _grandTotal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOTAL')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keranjang kosong.'));
          }

          final cartItems = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                      bottom: 80), // Beri ruang untuk tombol
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final Product product = item['product'];
                    final int quantity = item['quantity'];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('$quantity'),
                      ),
                      title: Text(product.name),
                      trailing: Text('Rp. ${product.price * quantity}'),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('Rp. $_subtotal'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon (10%)'),
                        Text('- Rp. $_discount'),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Rp. $_grandTotal',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _grandTotal > 0 ? _goToPayment : null,
                child: const Text('Bayar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}