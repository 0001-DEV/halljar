class Listing {
  final String id;
  final String title;
  final double price;
  final List<String> images;
  final String status; // 'ACTIVE' or 'SOLD'
  final int views;
  final String category;
  final String storeId;
  final String storeName;
  final String estateId;

  Listing({
    required this.id,
    required this.title,
    required this.price,
    this.images = const [],
    this.status = 'ACTIVE',
    this.views = 0,
    this.category = 'General',
    required this.storeId,
    this.storeName = 'Vendor Store',
    this.estateId = 'est_citiview',
  });

  bool get isInStock => status == 'ACTIVE';

  String get primaryImage {
    if (images.isNotEmpty && images.first.isNotEmpty) {
      return images.first;
    }
    return 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=600&auto=format&fit=crop&q=80';
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    List<String> imgList = [];
    if (json['images'] is List) {
      imgList = (json['images'] as List).map((e) => e.toString()).toList();
    }
    return Listing(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Product',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      images: imgList,
      status: json['status'] ?? 'ACTIVE',
      views: json['views'] ?? 0,
      category: json['category'] ?? 'General',
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? 'Vendor Store',
      estateId: json['estateId'] ?? 'est_citiview',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'images': images,
      'status': status,
      'views': views,
      'category': category,
      'storeId': storeId,
      'storeName': storeName,
      'estateId': estateId,
    };
  }
}
