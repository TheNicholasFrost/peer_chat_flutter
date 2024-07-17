library peer_chat_flutter;

import 'src/peer_chat_plugin.dart';

export 'src/peer_chat_plugin.dart' show PeerConnectionState;

class PeerChatFlutter {
  static void registerWith() {}

  final PeerChatPlugin _plugin = PeerChatPlugin();
  String? _myPeerId;

  Stream<String> get messageStream => _plugin.messageStream;
  Stream<PeerConnectionState> get connectionStateStream => _plugin.connectionStateStream;
  String? get myPeerId => _myPeerId;

  Future<bool> initialize({String? host, int? port, String? path}) async {
    try {
      await _plugin.initialize(host: host, port: port, path: path);
      _myPeerId = await _plugin.getPeerId();
      return _myPeerId != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> connectToPeer(String peerId) async {
    try {
      await _plugin.connectToPeer(peerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendMessage(String message) async {
    try {
      await _plugin.sendMessage(message);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reconnect() async {
    try {
      await _plugin.reconnect();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> closeConnection() async {
    try {
      await _plugin.closeConnection();
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() => _plugin.dispose();
}
