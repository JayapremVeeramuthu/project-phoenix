import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/network/api_client.dart';

class Product {
  final String id;
  final String category;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class ProductsRepository {
  final ApiClient? _apiClient;
  List<Product> _productsList = [];

  ProductsRepository([this._apiClient]) {
    _productsList = List.from(_bootstrapProducts);
    loadProductsData();
  }

  Future<void> loadProductsData() async {
    try {
      final remoteList = await getProductsRemote();
      if (remoteList.isNotEmpty) {
        _productsList = remoteList;
      }
    } catch (_) {}
  }

  final List<Product> _bootstrapProducts = [
    Product(
      id: 'p-01',
      category: 'Electrical Switches',
      name: 'Phoenix Smart Switch 6-Gang',
      description: 'Elegant modular touch switch board, compatible with Alexa & Google Assistant.',
      price: 2499.00,
      imageUrl: 'assets/products/switch.png',
    ),
    Product(
      id: 'p-02',
      category: 'Water Pumps',
      name: 'Phoenix Super Suction 1HP Pump',
      description: 'Heavy duty copper-winding water pump, self-priming with automatic float trigger.',
      price: 6899.00,
      imageUrl: 'assets/products/pump.png',
    ),
    Product(
      id: 'p-03',
      category: 'Fans',
      name: 'Phoenix BLDC Premium Ceiling Fan',
      description: 'Energy-saving 28W BLDC motor fan with remote control, noiseless operations.',
      price: 3499.00,
      imageUrl: 'assets/products/fan.png',
    ),
    Product(
      id: 'p-04',
      category: 'Safety Equipment',
      name: 'Phoenix MCB Distribution Board',
      description: 'Dual-door IP43 protection distribution board with pre-fitted busbar.',
      price: 1899.00,
      imageUrl: 'assets/products/mcb_box.png',
    ),
    Product(
      id: 'p-05',
      category: 'Lights',
      name: 'Phoenix 20W LED Batten Light',
      description: 'Cool day light 2000lm output tube light, surge protection up to 4kV.',
      price: 299.00,
      imageUrl: 'assets/products/light.png',
    ),
  ];

  Future<List<Product>> getProductsRemote({int page = 1, int limit = 10, String? filterCategory}) async {
    if (_apiClient == null) return _bootstrapProducts;
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (filterCategory != null) {
        queryParams['category'] = filterCategory;
      }
      final response = await _apiClient!.get('/products', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final list = response.data['data'] as List;
        return list.map((json) => Product.fromJson(json)).toList();
      }
    } catch (_) {}
    return _bootstrapProducts;
  }

  List<Product> getAllProducts() => _productsList;

  List<Product> getProductsByCategory(String category) {
    return _productsList
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}

final productsRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductsRepository(apiClient);
});
