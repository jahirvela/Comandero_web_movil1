class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final int category;
  /// Nombre real de la categoría del backend (ej. "Sandwiches", "Tacos").
  /// Si está presente, se usa para mostrar y filtrar en el menú del mesero.
  final String? categoryName;
  final bool available;
  final bool hot;
  final List<String>? extras;
  final Map<String, dynamic>? customizations;
  final List<ProductSize> sizes;
  final bool hasSizes;
  final double descuentoPorcentaje;
  final bool descuentoActivo;
  final DateTime? descuentoInicio;
  final DateTime? descuentoFin;
  final double? precioOriginal;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.category,
    this.categoryName,
    required this.available,
    this.hot = false,
    this.extras,
    this.customizations,
    this.sizes = const [],
    this.hasSizes = false,
    this.descuentoPorcentaje = 0,
    this.descuentoActivo = false,
    this.descuentoInicio,
    this.descuentoFin,
    this.precioOriginal,
  });

  /// Nombre de categoría para mostrar: el del backend si existe, si no el del enum.
  String get displayCategoryName =>
      (categoryName != null && categoryName!.isNotEmpty)
          ? categoryName!
          : ProductCategory.getCategoryName(category);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final sizes = (json['sizes'] as List<dynamic>?)
            ?.map((s) => ProductSize.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      image: json['image'],
      category: json['category'],
      categoryName: json['categoryName'] as String?,
      available: json['available'],
      hot: json['hot'] ?? false,
      extras: json['extras'] != null ? List<String>.from(json['extras']) : null,
      customizations: json['customizations'],
      sizes: sizes,
      hasSizes: sizes.isNotEmpty || (json['hasSizes'] as bool? ?? false),
      descuentoPorcentaje: (json['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0,
      descuentoActivo: json['descuentoActivo'] as bool? ?? false,
      descuentoInicio: json['descuentoInicio'] != null
          ? DateTime.tryParse(json['descuentoInicio'].toString())?.toLocal()
          : null,
      descuentoFin: json['descuentoFin'] != null
          ? DateTime.tryParse(json['descuentoFin'].toString())?.toLocal()
          : null,
      precioOriginal: (json['precioOriginal'] as num?)?.toDouble(),
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
      if (categoryName != null) 'categoryName': categoryName,
      'available': available,
      'hot': hot,
      'extras': extras,
      'customizations': customizations,
      'sizes': sizes.map((s) => s.toJson()).toList(),
      'hasSizes': hasSizes,
      'descuentoPorcentaje': descuentoPorcentaje,
      'descuentoActivo': descuentoActivo,
      'descuentoInicio': descuentoInicio?.toIso8601String(),
      'descuentoFin': descuentoFin?.toIso8601String(),
      if (precioOriginal != null) 'precioOriginal': precioOriginal,
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? image,
    int? category,
    String? categoryName,
    bool? available,
    bool? hot,
    List<String>? extras,
    Map<String, dynamic>? customizations,
    List<ProductSize>? sizes,
    bool? hasSizes,
    double? descuentoPorcentaje,
    bool? descuentoActivo,
    DateTime? descuentoInicio,
    DateTime? descuentoFin,
    double? precioOriginal,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      available: available ?? this.available,
      hot: hot ?? this.hot,
      extras: extras ?? this.extras,
      customizations: customizations ?? this.customizations,
      sizes: sizes ?? this.sizes,
      hasSizes: hasSizes ?? this.hasSizes,
      descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
      descuentoActivo: descuentoActivo ?? this.descuentoActivo,
      descuentoInicio: descuentoInicio ?? this.descuentoInicio,
      descuentoFin: descuentoFin ?? this.descuentoFin,
      precioOriginal: precioOriginal ?? this.precioOriginal,
    );
  }
}

class ProductSize {
  final int? id;
  final String name;
  final double price;
  final double? originalPrice;

  ProductSize({
    this.id,
    required this.name,
    required this.price,
    this.originalPrice,
  });

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      id: (json['id'] as num?)?.toInt(),
      name: (json['name'] ?? json['nombre'] ?? json['etiqueta'] ?? '').toString(),
      price: (json['price'] ?? json['precio'] ?? 0).toDouble(),
      originalPrice: (json['precioOriginal'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      if (originalPrice != null) 'precioOriginal': originalPrice,
    };
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

