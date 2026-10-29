import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'chat_detail_screen.dart';

class AllChatsScreen extends StatefulWidget {
  const AllChatsScreen({super.key});

  @override
  State<AllChatsScreen> createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends State<AllChatsScreen> {
  List<Conversation> _conversations = [];
  Map<String, String> _readTimestamps = {};
  bool _isLoading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final store = AuthService.currentStore;
    if (store == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final list = await ApiService.fetchVendorConversations(store.id);
      final readMap = await AuthService.getReadTimestamps();
      if (mounted) {
        setState(() {
          _conversations = list;
          _readTimestamps = readMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isConversationUnread(Conversation c) {
    if (c.messageCount == 0) return false;
    final lastRead = _readTimestamps[c.id];
    if (lastRead == null) return true;
    return c.updatedAt.isAfter(DateTime.parse(lastRead));
  }

  void _markAllRead() async {
    for (var c in _conversations) {
      await AuthService.markConversationRead(c.id);
    }
    final updatedMap = await AuthService.getReadTimestamps();
    if (mounted) {
      setState(() => _readTimestamps = updatedMap);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All chats marked as read'),
          backgroundColor: Color(0xFF0F766E),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conversations.where((c) {
      final matchName = c.buyerName.toLowerCase().contains(_filter.toLowerCase());
      final matchListing = (c.listingTitle ?? '').toLowerCase().contains(_filter.toLowerCase());
      final matchMsg = c.lastMessage.toLowerCase().contains(_filter.toLowerCase());
      return matchName || matchListing || matchMsg;
    }).toList();

    final unreadTotal = _conversations.where(_isConversationUnread).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Chats & Inquiries',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            Text(
              unreadTotal > 0 ? '$unreadTotal unread conversations' : 'All conversations up to date',
              style: TextStyle(fontSize: 11, color: unreadTotal > 0 ? const Color(0xFFEF4444) : Colors.black45, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (unreadTotal > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF0F766E)),
              label: const Text('Mark Read', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w800, fontSize: 12)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : Column(
              children: [
                // Search Input
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: TextField(
                    onChanged: (val) => setState(() => _filter = val),
                    decoration: InputDecoration(
                      hintText: 'Search inquiries by buyer or item...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black45),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                // Conversations List
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF0F766E),
                    onRefresh: _loadConversations,
                    child: filtered.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(50)),
                                    child: const Text('💬', style: TextStyle(fontSize: 40)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No inquiries found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'When residents inquire about your items,\ntheir messages will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, idx) {
                              final conv = filtered[idx];
                              final isUnread = _isConversationUnread(conv);

                              return InkWell(
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conv)),
                                  );
                                  _loadConversations();
                                },
                                child: Container(
                                  color: isUnread ? const Color(0xFFF0FDF4) : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Buyer Avatar
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: const Color(0xFF0F766E),
                                            child: Text(
                                              conv.buyerName.isNotEmpty ? conv.buyerName[0].toUpperCase() : 'U',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                                            ),
                                          ),
                                          if (isUnread)
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),

                                      // Inquiry Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    conv.buyerName,
                                                    style: TextStyle(
                                                      fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                                                      fontSize: 14,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _formatTimestamp(conv.updatedAt),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isUnread ? const Color(0xFF0F766E) : Colors.black45,
                                                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),

                                            // Listing Chip if available
                                            if (conv.listingTitle != null && conv.listingTitle!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text('📦 ', style: TextStyle(fontSize: 10)),
                                                          ConstrainedBox(
                                                            constraints: const BoxConstraints(maxWidth: 160),
                                                            child: Text(
                                                              conv.listingTitle!,
                                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          if (conv.listingPrice != null) ...[
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '₦${conv.listingPrice!.toStringAsFixed(0)}',
                                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                    if (conv.buyerUnit.isNotEmpty) ...[
                                                      const SizedBox(width: 6),
                                                      Text('• Unit ${conv.buyerUnit}', style: const TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w600)),
                                                    ],
                                                  ],
                                                ),
                                              ),

                                            // Last message snippet
                                            Text(
                                              conv.lastMessage,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isUnread ? const Color(0xFF1E293B) : Colors.black54,
                                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
