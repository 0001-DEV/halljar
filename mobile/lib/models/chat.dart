class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isOffer;
  final double? offeredPrice;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isOffer = false,
    this.offeredPrice,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isOffer: json['isOffer'] ?? false,
      offeredPrice: json['offeredPrice'] != null ? (json['offeredPrice'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isOffer': isOffer,
      'offeredPrice': offeredPrice,
    };
  }
}

class Conversation {
  final String id;
  final String storeId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerUnit;
  final String? listingTitle;
  final double? listingPrice;
  final String lastMessage;
  final DateTime updatedAt;
  final int messageCount;

  Conversation({
    required this.id,
    required this.storeId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerUnit = '',
    this.listingTitle,
    this.listingPrice,
    required this.lastMessage,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final buyerMap = json['buyer'] as Map<String, dynamic>?;
    final listingMap = json['listing'] as Map<String, dynamic>?;

    return Conversation(
      id: json['id'] ?? '',
      storeId: json['storeId'] ?? '',
      buyerId: json['buyerId'] ?? '',
      buyerName: buyerMap?['fullName'] ?? 'Estate Resident',
      buyerPhone: buyerMap?['phoneNumber'] ?? '',
      buyerUnit: buyerMap?['unit'] ?? '',
      listingTitle: listingMap?['title'],
      listingPrice: listingMap?['price'] != null ? (listingMap!['price'] as num).toDouble() : null,
      lastMessage: json['lastMessage'] ?? 'Conversation started',
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      messageCount: json['messageCount'] ?? 0,
    );
  }
}
