import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../models/store.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Store? _store;
  List<Listing> _listings = [];
  bool _isLoading = true;

  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 21, minute: 0);

  final List<String> _deleteConfirmationWords = [
    'DELETE-MY-ACCOUNT',
    'REMOVE-PERMANENTLY',
    'HALLJAR-CONFIRM-ERASE',
    'GOODBYE-FOREVER',
    'CANCEL-AND-DELETE',
    'PERMANENT-REMOVAL',
  ];

  @override
  void initState() {
    super.initState();
    _store = AuthService.currentStore;
    if (_store != null) {
      _parseHours(_store!.openTime, _store!.closeTime);
    }
    _loadDashboardData();
  }

  void _parseHours(String open, String close) {
    try {
      final p1 = open.split(':');
      final p2 = close.split(':');
      _openTime = TimeOfDay(hour: int.parse(p1[0]), minute: int.parse(p1[1]));
      _closeTime = TimeOfDay(hour: int.parse(p2[0]), minute: int.parse(p2[1]));
    } catch (_) {}
  }

  void _loadDashboardData() async {
    final s = AuthService.currentStore;
    if (s == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final catalog = await ApiService.fetchStoreCatalog(s.id);
      if (mounted) {
        setState(() {
          if (catalog['store'] != null) _store = catalog['store'];
          _listings = catalog['listings'];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSaveHours() async {
    if (_store == null) return;
    final oStr = '${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}';
    final cStr = '${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}';

    final ok = await ApiService.updateStoreHours(storeId: _store!.id, openTime: oStr, closeTime: cStr);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Operating hours updated successfully!')));
    }
  }

  void _handleToggleStock(Listing item) async {
    final ok = await ApiService.toggleListingStatus(item.id);
    if (ok) _loadDashboardData();
  }

  void _handleDeleteListing(Listing item) async {
    final ok = await ApiService.deleteListing(item.id);
    if (ok) _loadDashboardData();
  }

  void _handleLogout() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showDeleteAccountDialog() {
    final randomWord = _deleteConfirmationWords[Random().nextInt(_deleteConfirmationWords.length)];
    final inputController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFFECDD3))),
          title: const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF991B1B))),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'This action is irreversible. Your store, inventory items, and customer chats will be permanently erased.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF43F5E), style: BorderStyle.solid)),
                child: Column(
                  children: [
                    const Text('TO CONFIRM, TYPE THIS EXACT WORD:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF9F1239), letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(randomWord, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFFBE123C))),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: inputController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type the word above',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) {
                  setModalState(() {
                    canDelete = val.trim().toUpperCase() == randomWord.toUpperCase();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? const Color(0xFFE11D48) : const Color(0xFFFDA4AF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: canDelete
                  ? () async {
                      Navigator.pop(ctx);
                      final user = AuthService.currentUser;
                      if (user != null) {
                        try {
                          await ApiService.deleteAccount(userId: user.id, phoneNumber: user.phoneNumber);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Account permanently deleted')));
                          _handleLogout();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  : null,
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _store;
    final inStockCount = _listings.where((l) => l.isInStock).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Store Dashboard', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboardData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Store Header Banner Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover Image
                    if (s?.effectiveCover != null && s!.effectiveCover.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(s.effectiveCover, height: 110, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 110, color: const Color(0xFF0F766E))),
                      )
                    else
                      Container(height: 90, color: const Color(0xFF0F766E)),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFCCFBF1),
                            backgroundImage: s?.logo != null && s!.logo!.isNotEmpty ? NetworkImage(s.logo!) : null,
                            child: s?.logo == null ? const Text('🏬', style: TextStyle(fontSize: 22)) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(s?.storeName ?? 'My Store', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: s?.isOpen == true ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s?.isOpen == true ? '● OPEN' : '● CLOSED',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: s?.isOpen == true ? const Color(0xFF15803D) : const Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${s?.estateName ?? 'Warewa'} • ${s?.category ?? 'Supermarket'}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Store Operating Hours Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('⏰ Operating Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: _openTime);
                              if (t != null) setState(() => _openTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8)),
                              child: Text('Opens: ${_openTime.format(context)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: _closeTime);
                              if (t != null) setState(() => _closeTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(8)),
                              child: Text('Closes: ${_closeTime.format(context)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _handleSaveHours,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Customer Rating Metric Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Rating', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        Text('Based on estate buyer reviews', style: TextStyle(fontSize: 10, color: Colors.black45)),
                      ],
                    ),
                    Text(
                      '${s?.ratingAvg.toStringAsFixed(1) ?? '5.0'} ⭐ (${s?.ratingCount ?? 0})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Shelves & Inventory Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📦 Store Shelves & Inventory', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  Text('${_listings.length} items ($inStockCount in stock)', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 8),

              // Inventory Listing Items
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
              else if (_listings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(26),
                  alignment: Alignment.center,
                  child: const Text('No products on your shelves yet.', style: TextStyle(color: Colors.black54)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _listings.length,
                  itemBuilder: (ctx, i) {
                    final item = _listings[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.primaryImage, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.black12)),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                Text('₦${item.price.toStringAsFixed(0)} • ${item.category}', style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),

                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _handleToggleStock(item),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: BorderSide(color: item.isInStock ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                                ),
                                child: Text(item.isInStock ? 'In Stock' : 'Sold Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item.isInStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE11D48)),
                                onPressed: () => _handleDeleteListing(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Bottom Actions: Logout & Delete Account Side by Side
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Text('🚪', style: TextStyle(fontSize: 14)),
                        label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDeleteAccountDialog,
                        icon: const Text('🗑️', style: TextStyle(fontSize: 14)),
                        label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE11D48))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFFFF1F2),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
