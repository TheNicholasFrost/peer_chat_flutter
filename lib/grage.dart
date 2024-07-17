import 'dart:async';
import 'package:flutter/foundation.dart';
import 'peer_chat_plugin.dart';

/// A Flutter plugin for peer-to-peer chat functionality.
class PeerChatFlutter {
  final PeerChatPlugin _plugin = PeerChatPlugin();
  String? _myPeerId;

  /// Stream of incoming messages from connected peers.
  Stream<String> get messageStream => _plugin.messageStream;

  /// The current peer's ID.
  String? get myPeerId => _myPeerId;

  /// Initializes the peer connection.
  Future<bool> initialize({String? host, int? port, String? path}) async {
    try {
      await _plugin.initialize(
        host: host ?? '0.peerjs.com',
        port: port ?? 443,
        path: path ?? '/',
      );
      _myPeerId = await _plugin.getPeerId();
      return true;
    } catch (e) {
      debugPrint('Initialization error: $e');
      return false;
    }
  }

  /// Connects to another peer with the given [peerId].
  Future<bool> connectToPeer(String peerId) async {
    try {
      await _plugin.connectToPeer(peerId);
      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      return false;
    }
  }

  /// Sends a [message] to the connected peer.
  Future<bool> sendMessage(String message) async {
    try {
      await _plugin.sendMessage(message);
      return true;
    } catch (e) {
      debugPrint('Send message error: $e');
      return false;
    }
  }

  /// Disposes of the plugin, closing all connections and streams.
  void dispose() {
    _plugin.dispose();
  }
}
