class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final int category;
  final bool available;
  final bool hot;
  final List<String>? extras;
  final Map<String, dynamic>? customizations;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.category,
    required this.available,
    this.hot = false,
    this.extras,
    this.customizations,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      image: json['image'],
      category: json['category'],
      available: json['available'],
      hot: json['hot'] ?? false,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      customizations: json['customizations'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
      'available': available,
      'hot': hot,
      'extras': extras,
      'customizations': customizations,
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? image,
    int? category,
    bool? available,
    bool? hot,
    List<String>? extras,
    Map<String, dynamic>? customizations,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      available: available ?? this.available,
      hot: hot ?? this.hot,
      extras: extras ?? this.extras,
      customizations: customizations ?? this.customizations,
    );
  }
}

class CartItem {
  final String id;
  final ProductModel product;
  final Map<String, dynamic> customizations;
  final String tableId;

  CartItem({
    required this.id,
    required this.product,
    required this.customizations,
    required this.tableId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: ProductModel.fromJson(json['product']),
      customizations: json['customizations'] ?? {},
      tableId: json['tableId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'customizations': customizations,
      'tableId': tableId,
    };
  }
}

// Categorías de productos
class ProductCategory {
  static const int tacos = 1;
  static const int platosEspeciales = 2;
  static const int acompanamientos = 3;
  static const int bebidas = 4;
  static const int extras = 5;
  static const int consomes = 6;

  static String getCategoryName(int categoryId) {
    switch (categoryId) {
      case tacos:
        return 'Tacos';
      case platosEspeciales:
        return 'Platos Especiales';
      case acompanamientos:
        return 'Acompañamientos';
      case bebidas:
        return 'Bebidas';
      case extras:
        return 'Extras';
      case consomes:
        return 'Consomes';
      default:
        return 'Sin categoría';
    }
  }

  static String getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case tacos:
        return '🌮';
      case platosEspeciales:
        return '🍽️';
      case acompanamientos:
        return '🥬';
      case bebidas:
        return '🥤';
      case extras:
        return '🌶️';
      case consomes:
        return '🍲';
      default:
        return '🍽️';
    }
  }
}

