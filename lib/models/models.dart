class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Product {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? imageUrl;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        categoryId: json['category_id'],
        name: json['name'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
        imageUrl: json['image_url'],
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;

  Customer({required this.id, required this.name, this.phone, this.address, this.notes});

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        address: json['address'],
        notes: json['notes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
      };
}

class Sale {
  final String id;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;

  Sale({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'],
        customerId: json['customer_id'],
        customerName: json['customer_name'],
        customerPhone: json['customer_phone'],
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['payment_method'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        id: json['id'],
        saleId: json['sale_id'],
        productId: json['product_id'],
        productName: json['product_name'],
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
      );
}

class CartLine {
  final Product product;
  int quantity;

  CartLine({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;
}

class TicketLine {
  final String productName;
  final int quantity;
  final double unitPrice;

  TicketLine({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  factory TicketLine.fromCart(CartLine line) => TicketLine(
        productName: line.product.name,
        quantity: line.quantity,
        unitPrice: line.product.price,
      );

  factory TicketLine.fromSaleItem(SaleItem item) => TicketLine(
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.price,
      );
}
