import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/store/data/repositories/products_repository.dart';
import 'package:project_phoenix_customer/features/store/presentation/cart_notifier.dart';

class ProductStoreScreen extends ConsumerWidget {
  const ProductStoreScreen({super.key});

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return const CartBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsRepositoryProvider).getAllProducts();
    final cart = ref.watch(cartNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product Store',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: isSeniorMode ? 24 : 20),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => _showCartSheet(context, ref),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.fold(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No products available',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 16,
                      )),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900
                    ? 4
                    : MediaQuery.of(context).size.width > 600
                        ? 3
                        : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isSeniorMode ? 0.58 : 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image placeholder with category badge
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                              ),
                              child: Icon(
                                _getCategoryIcon(product.category),
                                size: isSeniorMode ? 48 : 40,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Product details
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isSeniorMode ? 15 : 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  height: 1.3,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: isSeniorMode ? 17 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(
                                    width: isSeniorMode ? 40 : 36,
                                    height: isSeniorMode ? 40 : 36,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.add_shopping_cart,
                                          color: theme.colorScheme.primary,
                                          size: isSeniorMode ? 22 : 20),
                                      onPressed: () {
                                        ref
                                            .read(
                                                cartNotifierProvider.notifier)
                                            .addProduct(product);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${product.name} added to cart!'),
                                            behavior: SnackBarBehavior.floating,
                                            duration:
                                                const Duration(seconds: 1),
                                          ),
                                        );
                                      },
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
                );
              },
            ),
      // Floating cart summary bar
      bottomNavigationBar: cart.isNotEmpty
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.fold(0, (sum, item) => sum + item.quantity)} items',
                            style: TextStyle(
                              fontSize: isSeniorMode ? 14 : 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '₹${ref.read(cartNotifierProvider.notifier).totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isSeniorMode ? 20 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showCartSheet(context, ref),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                            isSeniorMode ? 160 : 140, isSeniorMode ? 52 : 44),
                      ),
                      child: const Text('View Cart'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'hardware':
        return Icons.hardware_rounded;
      case 'safety':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.settings_rounded;
    }
  }
}

class CartBottomSheet extends ConsumerStatefulWidget {
  const CartBottomSheet({super.key});

  @override
  ConsumerState<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends ConsumerState<CartBottomSheet> {
  String _selectedPayment = 'UPI';
  final _couponController = TextEditingController();
  double _discountRate = 0.0;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));
    final basePrice = ref.read(cartNotifierProvider.notifier).totalPrice;
    final discountAmount = basePrice * _discountRate;
    final grandTotal = basePrice - discountAmount;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shopping Cart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      ref.read(cartNotifierProvider.notifier).clearCart(),
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const Divider(),
          if (cart.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add products to get started',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return ListTile(
                    title: Text(item.product.name,
                        style: TextStyle(fontSize: isSeniorMode ? 18 : 14)),
                    subtitle: Text('₹${item.product.price.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => ref
                              .read(cartNotifierProvider.notifier)
                              .removeProduct(item.product),
                        ),
                        Text('${item.quantity}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => ref
                              .read(cartNotifierProvider.notifier)
                              .addProduct(item.product),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    decoration: const InputDecoration(
                      hintText: 'Coupon Code (PHOENIX15)',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_couponController.text.trim().toUpperCase() ==
                          'PHOENIX15') {
                        setState(() {
                          _discountRate = 0.15;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Promo applied! 15% discount.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid coupon code'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 44),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Select Payment Mode',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['UPI', 'Card', 'Cash'].map((mode) {
                final isSelected = _selectedPayment == mode;
                return ChoiceChip(
                  label: Text(mode),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedPayment = mode;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₹${basePrice.toStringAsFixed(0)}'),
              ],
            ),
            if (discountAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount (15%)',
                        style: TextStyle(color: Colors.green)),
                    Text('-₹${discountAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '₹${grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cartNotifierProvider.notifier).clearCart();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order Placed! Payment: $_selectedPayment. Invoice generated.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
              ),
              child: const Text('Checkout & Generate Invoice'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
