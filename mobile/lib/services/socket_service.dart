import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat.dart';

class SocketService {
  static WebSocketChannel? _channel;
  static final List<Function(Message)> _messageListeners = [];

  static void addListener(Function(Message) onMessage) {
    _messageListeners.add(onMessage);
  }

  static void removeListener(Function(Message) onMessage) {
    _messageListeners.remove(onMessage);
  }

  static void connect(String host) {
    try {
      final wsUrl = Uri.parse(host.replaceFirst('http', 'ws'));
      _channel = WebSocketChannel.connect(wsUrl);

      _channel?.stream.listen((event) {
        try {
          final data = jsonDecode(event);
          if (data['type'] == 'NEW_MESSAGE' && data['message'] != null) {
            final msg = Message.fromJson(data['message']);
            for (var listener in _messageListeners) {
              listener(msg);
            }
          }
        } catch (_) {}
      }, onError: (_) {}, onDone: () {});
    } catch (_) {}
  }

  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
