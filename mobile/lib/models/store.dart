class Store {
  final String id;
  final String userId;
  final String storeName;
  final String category;
  final String? cover;
  final String? coverPhoto;
  final String? logo;
  final String estateId;
  final String estateName;
  final String openTime;
  final String closeTime;
  final double ratingAvg;
  final int ratingCount;
  final bool isOpen;
  final String bio;

  Store({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.category,
    this.cover,
    this.coverPhoto,
    this.logo,
    required this.estateId,
    this.estateName = 'Warewa',
    this.openTime = '08:00',
    this.closeTime = '21:00',
    this.ratingAvg = 5.0,
    this.ratingCount = 0,
    this.isOpen = true,
    this.bio = '',
  });

  String get effectiveCover => cover ?? coverPhoto ?? '';

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      storeName: json['storeName'] ?? '',
      category: json['category'] ?? 'Supermarket',
      cover: json['cover'],
      coverPhoto: json['coverPhoto'],
      logo: json['logo'],
      estateId: json['estateId'] ?? 'est_citiview',
      estateName: json['estateName'] ?? 'Citi-View',
      openTime: json['openTime'] ?? '08:00',
      closeTime: json['closeTime'] ?? '21:00',
      ratingAvg: (json['ratingAvg'] is num) ? (json['ratingAvg'] as num).toDouble() : 5.0,
      ratingCount: json['ratingCount'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      bio: json['bio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'storeName': storeName,
      'category': category,
      'cover': cover,
      'coverPhoto': coverPhoto,
      'logo': logo,
      'estateId': estateId,
      'estateName': estateName,
      'openTime': openTime,
      'closeTime': closeTime,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'isOpen': isOpen,
      'bio': bio,
    };
  }
}
