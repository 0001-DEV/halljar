import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../models/store.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../chats/all_chats_screen.dart';
import '../chats/chat_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _selectedEstate = 'est_citiview';
  String _searchQuery = '';
  List<Listing> _listings = [];
  List<Store> _stores = [];
  int _unreadChatCount = 0;
  bool _isLoading = true;

  // Cart quantity tracker: { listingId: count }
  final Map<String, int> _cartQuantities = {};

  final List<Map<String, String>> _estates = [
    {'id': 'est_citiview', 'name': 'Citi-View Estate'},
    {'id': 'est_warewa', 'name': 'Warewa'},
    {'id': 'est_arepo', 'name': 'Arepo'},
    {'id': 'est_opic', 'name': 'Opic'},
    {'id': 'est_ibafo', 'name': 'Ibafo'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUnreadChats();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      final listingsFuture = ApiService.fetchListings(query: _searchQuery, estateId: _selectedEstate);
      final storesFuture = ApiService.fetchStores(estateId: _selectedEstate);

      final results = await Future.wait([listingsFuture, storesFuture]);
      if (mounted) {
        setState(() {
          _listings = results[0] as List<Listing>;
          _stores = results[1] as List<Store>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkUnreadChats() async {
    final store = AuthService.currentStore;
    if (store == null) return;
    try {
      final convs = await ApiService.fetchVendorConversations(store.id);
      final readMap = await AuthService.getReadTimestamps();

      int unread = 0;
      for (var c in convs) {
        if (c.messageCount > 0) {
          final lastRead = readMap[c.id];
          if (lastRead == null || c.updatedAt.isAfter(DateTime.parse(lastRead))) {
            unread++;
          }
        }
      }

      if (mounted) setState(() => _unreadChatCount = unread);
    } catch (_) {}
  }

  void _handleLogout() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final store = AuthService.currentStore;
    final isVendor = store != null || (user != null && user.isSeller);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Row(
          children: [
            Text('🏛️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 6),
            Text(
              'Halljar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
            ),
          ],
        ),
        actions: [
          if (isVendor) ...[
            // All Chats Button with Top-Right Red Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllChatsScreen()),
                    );
                    _checkUnreadChats();
                  },
                  icon: const Text('💬', style: TextStyle(fontSize: 14)),
                  label: const Text('All Chats', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
                if (_unreadChatCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),

            // View Dashboard Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCCFBF1),
                foregroundColor: const Color(0xFF0F766E),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('View Dashboard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
          ] else if (user != null) ...[
            // Individual Buyer Options
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupScreen(isUpgradingFromIndividual: true)),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('+ Register Business', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: _handleLogout,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F2),
                foregroundColor: const Color(0xFFE11D48),
                side: const BorderSide(color: Color(0xFFFECDD3)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('🚪 Log Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          _checkUnreadChats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Estate Location Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search bakes, gadgets, food, groceries...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) {
                        _searchQuery = val.trim();
                        _loadData();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedEstate,
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                      items: _estates.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['name']!))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedEstate = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Top Businesses & Stores Section
              const Text(
                '🏪 Top Businesses & Stores',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stores.length,
                  itemBuilder: (ctx, i) {
                    final s = _stores[i];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          if (s.logo != null && s.logo!.isNotEmpty)
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(s.logo!, width: 20, height: 20, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('🏬', style: TextStyle(fontSize: 14))))
                          else
                            const Text('🏬', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(s.storeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // In-Stock Items Today
              const Text(
                '🔥 In-Stock Items Today',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_listings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.center,
                  child: const Text('No products currently listed in this estate.\nPull down to refresh.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _listings.length,
                  itemBuilder: (ctx, i) {
                    final item = _listings[i];
                    final isMyStoreItem = store != null && item.storeId == store.id;
                    final qty = _cartQuantities[item.id] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        // Black border if item belongs to logged-in vendor!
                        border: Border.all(
                          color: isMyStoreItem ? Colors.black : const Color(0xFFE2E8F0),
                          width: isMyStoreItem ? 2.0 : 1.0,
                        ),
                        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.primaryImage,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.black12, child: const Icon(Icons.image_not_supported)),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.isInStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.isInStock ? 'IN STOCK' : 'SOLD OUT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: item.isInStock ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${item.category} • ${item.storeName}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  '₦${item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Quantity / Add Button
                          if (qty == 0)
                            ElevatedButton(
                              onPressed: () => setState(() => _cartQuantities[item.id] = 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: const Color(0xFF0F172A),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                                    onPressed: () => setState(() {
                                      if (qty > 1) {
                                        _cartQuantities[item.id] = qty - 1;
                                      } else {
                                        _cartQuantities.remove(item.id);
                                      }
                                    }),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                    onPressed: () => setState(() => _cartQuantities[item.id] = qty + 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
