import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final List<Message> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markRead();
    _loadMessages();
    SocketService.addListener(_handleIncomingMessage);
  }

  @override
  void dispose() {
    SocketService.removeListener(_handleIncomingMessage);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markRead() async {
    await AuthService.markConversationRead(widget.conversation.id);
  }

  void _handleIncomingMessage(Message msg) {
    if (msg.conversationId == widget.conversation.id) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
        _markRead();
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final list = await ApiService.fetchMessages(widget.conversation.id);
      if (mounted) {
        setState(() {
          _messages.addAll(list);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({bool isOffer = false, double? offeredPrice}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && !isOffer) return;

    final user = AuthService.currentUser;
    final store = AuthService.currentStore;
    final senderId = user?.id ?? store?.id ?? 'vendor';
    final senderName = store?.storeName ?? user?.fullName ?? 'Vendor';

    setState(() => _isSending = true);
    _msgController.clear();

    final sentMsg = await ApiService.sendMessage(
      convId: widget.conversation.id,
      senderId: senderId,
      senderName: senderName,
      text: text.isNotEmpty ? text : (isOffer ? 'Made an offer: ₦${offeredPrice?.toStringAsFixed(0)}' : ''),
      isOffer: isOffer,
      offeredPrice: offeredPrice,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (sentMsg != null) {
          _messages.add(sentMsg);
        } else {
          // Fallback optimistic message
          _messages.add(
            Message(
              id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
              conversationId: widget.conversation.id,
              senderId: senderId,
              senderName: senderName,
              text: text,
              timestamp: DateTime.now(),
              isOffer: isOffer,
              offeredPrice: offeredPrice,
            ),
          );
        }
      });
      _scrollToBottom();
    }
  }

  void _showOfferDialog() {
    final offerCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🏷️ ', style: TextStyle(fontSize: 20)),
            Text('Propose Special Offer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your discounted or agreed price for this customer:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: offerCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '₦ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F766E), fontSize: 16),
                hintText: 'e.g. 4500',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(offerCtrl.text.trim());
              if (val != null && val > 0) {
                Navigator.of(ctx).pop();
                _sendMessage(isOffer: true, offeredPrice: val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Offer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.currentUser?.id ?? AuthService.currentStore?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0F766E),
              child: Text(
                widget.conversation.buyerName.isNotEmpty ? widget.conversation.buyerName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.buyerName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.conversation.buyerUnit.isNotEmpty
                        ? 'Unit ${widget.conversation.buyerUnit} • ${widget.conversation.buyerPhone}'
                        : widget.conversation.buyerPhone,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pinned Listing Card & Anti-Scam Banner
          if (widget.conversation.listingTitle != null && widget.conversation.listingTitle!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Text('📦', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.listingTitle!,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.conversation.listingPrice != null)
                          Text(
                            'Listed at ₦${widget.conversation.listingPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🛡️ ', style: TextStyle(fontSize: 10)),
                        Text('Verified Resident', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, idx) {
                      final msg = _messages[idx];
                      final isMine = msg.senderId == currentUserId ||
                          (AuthService.currentStore != null && msg.senderId == AuthService.currentStore!.id);

                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine ? const Color(0xFF0F766E) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isMine ? 14 : 2),
                              bottomRight: Radius.circular(isMine ? 2 : 14),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Offer Tag
                              if (msg.isOffer && msg.offeredPrice != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isMine ? const Color(0xFF115E59) : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🏷️ ', style: TextStyle(fontSize: 11)),
                                      Text(
                                        'Price Offer: ₦${msg.offeredPrice!.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: isMine ? const Color(0xFFFDE047) : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (msg.text.isNotEmpty)
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMine ? Colors.white : const Color(0xFF0F172A),
                                    height: 1.3,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('h:mm a').format(msg.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMine ? Colors.white70 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Make Offer Button
                  IconButton(
                    onPressed: _showOfferDialog,
                    icon: const Text('🏷️', style: TextStyle(fontSize: 20)),
                    tooltip: 'Make Offer',
                  ),
                  const SizedBox(width: 4),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _isSending ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
