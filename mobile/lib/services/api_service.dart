import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/store.dart';
import '../models/listing.dart';
import '../models/chat.dart';

class ApiService {
  // Use Vercel live API or local development server (10.0.2.2 is Android host loopback)
  static String baseUrl = 'https://halljar.vercel.app/api';

  static void setBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }

  // Auth: Login
  static asyncLogin({
    required String phoneNumber,
    required String password,
    required String accountType,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'accountType': accountType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final user = User.fromJson(data['user']);
      final store = data['store'] != null ? Store.fromJson(data['store']) : null;
      return {'user': user, 'store': store};
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  // Auth: Request Signup OTP
  static Future<String> requestRegisterOtp(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/auth/register-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['code']?.toString() ?? '';
    } else {
      throw Exception(data['error'] ?? 'Failed to send verification code');
    }
  }

  // Auth: Verify Signup OTP
  static Future<Map<String, dynamic>> verifyRegisterOtp({
    required String phoneNumber,
    required String code,
    required String accountType,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify-register-otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'code': code,
        'accountType': accountType,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final user = User.fromJson(data['user']);
      final store = data['store'] != null ? Store.fromJson(data['store']) : null;
      return {'user': user, 'store': store};
    } else {
      throw Exception(data['error'] ?? 'Invalid verification code');
    }
  }

  // Auth: Delete Account
  static Future<bool> deleteAccount({required String userId, required String phoneNumber}) async {
    final url = Uri.parse('$baseUrl/auth/delete-account');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'phoneNumber': phoneNumber,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return true;
    } else {
      throw Exception(data['error'] ?? 'Failed to delete account');
    }
  }

  // Listings: Fetch Marketplace items
  static Future<List<Listing>> fetchListings({String? query, String? estateId}) async {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (estateId != null && estateId.isNotEmpty) params['estate'] = estateId;

    final uri = Uri.parse('$baseUrl/listings').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data is List) ? data : (data['listings'] as List? ?? []);
      return list.map((e) => Listing.fromJson(e)).toList();
    }
    return [];
  }

  // Stores: Fetch Verified Stores
  static Future<List<Store>> fetchStores({String? estateId}) async {
    final uri = Uri.parse('$baseUrl/stores${estateId != null ? '?estate=$estateId' : ''}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data is List) ? data : (data['stores'] as List? ?? []);
      return list.map((e) => Store.fromJson(e)).toList();
    }
    return [];
  }

  // Stores: Fetch Store Catalog
  static Future<Map<String, dynamic>> fetchStoreCatalog(String storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/catalog?includeAll=true');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final store = data['store'] != null ? Store.fromJson(data['store']) : null;
      final listings = (data['listings'] as List? ?? []).map((e) => Listing.fromJson(e)).toList();
      return {'store': store, 'listings': listings};
    }
    return {'store': null, 'listings': <Listing>[]};
  }

  // Vendor: Toggle In-Stock / Sold Out status
  static Future<bool> toggleListingStatus(String listingId) async {
    final url = Uri.parse('$baseUrl/listings/$listingId/toggle-stock');
    final response = await http.post(url);
    return response.statusCode == 200;
  }

  // Vendor: Delete Listing
  static Future<bool> deleteListing(String listingId) async {
    final url = Uri.parse('$baseUrl/listings/$listingId');
    final response = await http.delete(url);
    return response.statusCode == 200;
  }

  // Vendor: Update Store Operating Hours
  static Future<bool> updateStoreHours({
    required String storeId,
    required String openTime,
    required String closeTime,
  }) async {
    final url = Uri.parse('$baseUrl/stores/$storeId');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'openTime': openTime, 'closeTime': closeTime}),
    );
    return response.statusCode == 200;
  }

  // Chats: Fetch Vendor Conversations
  static Future<List<Conversation>> fetchVendorConversations(String storeId) async {
    final url = Uri.parse('$baseUrl/stores/$storeId/conversations');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List? ?? [];
      return data.map((e) => Conversation.fromJson(e)).toList();
    }
    return [];
  }

  // Chats: Fetch Messages
  static Future<List<Message>> fetchMessages(String convId) async {
    final url = Uri.parse('$baseUrl/conversations/$convId/messages');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List? ?? [];
      return data.map((e) => Message.fromJson(e)).toList();
    }
    return [];
  }

  // Chats: Send Message
  static Future<Message?> sendMessage({
    required String convId,
    required String senderId,
    required String senderName,
    required String text,
    bool isOffer = false,
    double? offeredPrice,
  }) async {
    final url = Uri.parse('$baseUrl/conversations/$convId/messages');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'isOffer': isOffer,
        'offeredPrice': offeredPrice,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Message.fromJson(data);
    }
    return null;
  }
}
